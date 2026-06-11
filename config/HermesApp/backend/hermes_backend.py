"""HermesBackend — the app's single source of truth.

Replaces the old HermesService.qml, which drove everything through curl/python3
subprocesses. This is plain in-process Python: httpx for HTTP + SSE, sqlite3 for
the DB, threads for anything blocking. It owns the message list and runs the SSE
event state machine; a thin QML coordinator (HermesService.qml) mirrors the
emitted signals into the ListModels the views bind to.
"""
from __future__ import annotations

import json
import os
import re
import threading
import time

import httpx
from PySide6.QtCore import (
    Property,
    QObject,
    QTimer,
    Signal,
    Slot,
)

from . import db, welcome

SETTINGS_PATH = os.path.expanduser("~/.config/HermesApp/settings.json")
DEFAULTS = {
    "apiBaseUrl": "http://127.0.0.1:8642",
    "apiKey": "",
    "hermesHome": "~/.hermes",
    "selectedModel": "",
}


class HermesBackend(QObject):
    # ── Coordinator-facing signals ─────────────────────────────
    sessionsReset = Signal(list)
    messagesReset = Signal(list)
    messageAppended = Signal("QVariant")
    messageUpdated = Signal(int, "QVariant")

    runStarted = Signal()
    runCompleted = Signal(str)
    runFailed = Signal(str)

    # ── Property notifications ─────────────────────────────────
    connectedChanged = Signal()
    currentSessionIdChanged = Signal()
    currentModelChanged = Signal()
    isRunningChanged = Signal()
    currentRunIdChanged = Signal()
    lastUsageChanged = Signal()
    lastErrorChanged = Signal()
    welcomeInfoChanged = Signal()
    configChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._lock = threading.Lock()
        self._messages: list[dict] = []

        # Config (loaded from settings.json, with env-key fallback)
        s = self._load_settings()
        self._apiBaseUrl = s["apiBaseUrl"]
        self._apiKey = s["apiKey"]
        self._hermesHome = s["hermesHome"]
        self._selectedModel = s["selectedModel"]
        self._envApiKey = ""

        # Runtime state
        self._connected = False
        self._currentSessionId = ""
        self._currentModel = ""
        self._isRunning = False
        self._currentRunId = ""
        self._lastUsage: dict = {}
        self._lastError = ""
        self._welcomeInfo: dict = {}

        # SSE gating
        self._accepting = False
        self._sseStop = threading.Event()

        self._client = httpx.Client(timeout=httpx.Timeout(10.0, read=None))

        self._healthTimer = QTimer(self)
        self._healthTimer.setInterval(15000)
        self._healthTimer.timeout.connect(self.checkHealth)

    # ───────────────────────────────────────────────────────────
    #  Lifecycle
    # ───────────────────────────────────────────────────────────
    def start(self) -> None:
        """Kick off the initial loads once QML is wired up."""
        self._discover_env_key()
        self._healthTimer.start()
        self.checkHealth()
        self.loadSessions()
        self.loadWelcomeInfo()

    # ───────────────────────────────────────────────────────────
    #  Settings
    # ───────────────────────────────────────────────────────────
    def _load_settings(self) -> dict:
        data = dict(DEFAULTS)
        try:
            with open(SETTINGS_PATH) as f:
                data.update({k: v for k, v in json.load(f).items() if k in DEFAULTS})
        except (OSError, ValueError):
            pass
        return data

    def _save_settings(self) -> None:
        os.makedirs(os.path.dirname(SETTINGS_PATH), exist_ok=True)
        try:
            with open(SETTINGS_PATH, "w") as f:
                json.dump(
                    {
                        "apiBaseUrl": self._apiBaseUrl,
                        "apiKey": self._apiKey,
                        "hermesHome": self._hermesHome,
                        "selectedModel": self._selectedModel,
                    },
                    f,
                    indent=2,
                )
        except OSError:
            pass

    def _discover_env_key(self) -> None:
        """When no explicit key is set, read API_SERVER_KEY from <home>/.env so
        the local gateway works out of the box."""
        if self._apiKey:
            return
        env_path = os.path.join(os.path.expanduser(self._hermesHome), ".env")
        try:
            with open(env_path) as f:
                for line in f:
                    m = re.match(
                        r"^\s*(?:export\s+)?API_SERVER_KEY=(.*)$", line.rstrip("\n")
                    )
                    if m:
                        self._envApiKey = m.group(1).strip().strip("\"'")
                        break
        except OSError:
            pass

    @property
    def _effective_key(self) -> str:
        return self._apiKey or self._envApiKey

    def _headers(self, json_body: bool = False) -> dict:
        h = {}
        if self._effective_key:
            h["Authorization"] = f"Bearer {self._effective_key}"
        if json_body:
            h["Content-Type"] = "application/json"
        return h

    # ───────────────────────────────────────────────────────────
    #  Threading helper
    # ───────────────────────────────────────────────────────────
    @staticmethod
    def _spawn(fn) -> None:
        # Daemon threads so a blocked SSE read can never hold up process exit.
        threading.Thread(target=fn, daemon=True).start()

    # ───────────────────────────────────────────────────────────
    #  Health
    # ───────────────────────────────────────────────────────────
    @Slot()
    def checkHealth(self) -> None:
        self._spawn(self._do_health)

    def _do_health(self) -> None:
        try:
            r = self._client.get(
                self._apiBaseUrl + "/health", headers=self._headers(), timeout=3.0
            )
            data = r.json()
            ok = data.get("status") in ("ok", "healthy")
            self._set_connected(ok)
            if data.get("model"):
                self._set_current_model(data["model"])
        except Exception:
            self._set_connected(False)

    # ───────────────────────────────────────────────────────────
    #  Sessions / messages (sqlite)
    # ───────────────────────────────────────────────────────────
    @Slot()
    def loadSessions(self) -> None:
        def work():
            try:
                rows = db.load_sessions(self._db_path())
            except Exception:
                rows = []
            self.sessionsReset.emit(rows)

        self._spawn(work)

    @Slot(str)
    def loadMessages(self, session_id: str) -> None:
        self._detach_run()
        self._set_current_session(session_id)
        with self._lock:
            self._messages = []
        self.messagesReset.emit([])

        def work():
            try:
                rows = db.load_messages(self._db_path(), session_id)
            except Exception:
                rows = []
            with self._lock:
                self._messages = list(rows)
            self.messagesReset.emit(rows)

        self._spawn(work)

    @Slot()
    def newChat(self) -> None:
        self._detach_run()
        self._set_current_session("")
        with self._lock:
            self._messages = []
        self.messagesReset.emit([])

    @Slot(int)
    def truncateTo(self, row: int) -> None:
        """Drop every row from `row` onward. Used by edit-and-resend: the user
        message is removed and its text loaded back into the input."""
        if self._isRunning:
            return
        with self._lock:
            if row < 0 or row > len(self._messages):
                return
            self._messages = self._messages[:row]
            snapshot = list(self._messages)
        self.messagesReset.emit(snapshot)

    @Slot(int, str)
    def resendFrom(self, row: int, text: str) -> None:
        """Truncate to before `row`, then send `text` as a fresh turn. Powers
        retry (resend the preceding user message) from the message actions."""
        if self._isRunning or not text.strip():
            return
        with self._lock:
            if row < 0 or row > len(self._messages):
                return
            self._messages = self._messages[:row]
            snapshot = list(self._messages)
        self.messagesReset.emit(snapshot)
        self.sendMessage(text)

    def _db_path(self) -> str:
        return os.path.join(os.path.expanduser(self._hermesHome), "state.db")

    # ───────────────────────────────────────────────────────────
    #  Welcome
    # ───────────────────────────────────────────────────────────
    @Slot()
    def loadWelcomeInfo(self) -> None:
        def work():
            try:
                info = welcome.gather(self._hermesHome)
            except Exception:
                info = {}
            self._set_welcome(info)

        self._spawn(work)

    # ───────────────────────────────────────────────────────────
    #  Send message → POST /v1/runs, then stream events
    # ───────────────────────────────────────────────────────────
    @Slot(str)
    def sendMessage(self, text: str) -> None:
        if self._isRunning or not text.strip():
            return
        history = self._conversation_history()

        self._append(db._row("user", content=text, timestamp=time.time()))
        self._append(
            db._row(
                "assistant",
                isStreaming=True,
                timestamp=time.time(),
                startedAt=time.time(),
                usage={},
                duration=0,
            )
        )

        body = {"input": text, "conversation_history": history}
        if self._currentSessionId:
            body["session_id"] = self._currentSessionId
        if self._selectedModel:
            body["model"] = self._selectedModel

        self._spawn(lambda: self._do_run(body))

    def _do_run(self, body: dict) -> None:
        try:
            r = self._client.post(
                self._apiBaseUrl + "/v1/runs",
                headers=self._headers(json_body=True),
                json=body,
                timeout=15.0,
            )
            resp = r.json()
        except Exception as e:
            self._fail_pending(f"Failed to start run: {e}")
            return

        run_id = resp.get("run_id")
        if not run_id:
            err = resp.get("error")
            if isinstance(err, dict):
                msg = err.get("message") or "Unknown error"
            elif isinstance(err, str):
                msg = err
            else:
                msg = "Gateway returned no run_id"
            self._fail_pending(msg)
            return

        self._set_current_run(run_id)
        self._set_running(True)
        self.runStarted.emit()
        self._stream_events(run_id)

    def _conversation_history(self) -> list[dict]:
        out = []
        with self._lock:
            snapshot = list(self._messages)
        for m in snapshot:
            if m["type"] in ("user", "assistant") and (m.get("content") or "").strip():
                out.append(
                    {
                        "role": "user" if m["type"] == "user" else "assistant",
                        "content": m["content"],
                    }
                )
        return out

    # ───────────────────────────────────────────────────────────
    #  SSE stream → GET /v1/runs/{id}/events
    # ───────────────────────────────────────────────────────────
    def _stream_events(self, run_id: str) -> None:
        self._accepting = True
        self._sseStop.clear()
        url = f"{self._apiBaseUrl}/v1/runs/{run_id}/events"
        try:
            with self._client.stream(
                "GET", url, headers=self._headers(), timeout=httpx.Timeout(5.0, read=300.0)
            ) as resp:
                for line in resp.iter_lines():
                    if self._sseStop.is_set() or run_id != self._currentRunId:
                        return
                    self._handle_sse_line(line)
        except Exception:
            pass
        finally:
            # Stream ended without an explicit terminal event — seal the bubble.
            if run_id == self._currentRunId and run_id:
                self._set_running(False)
                self._seal_streaming()

    def _handle_sse_line(self, line: str) -> None:
        if not self._accepting:
            return
        line = (line or "").strip()
        if not line or line.startswith(":") or not line.startswith("data: "):
            return
        try:
            event = json.loads(line[6:])
        except ValueError:
            return
        self._handle_event(event)

    def _handle_event(self, event: dict) -> None:
        t = event.get("event")
        if t == "message.delta":
            self._append_delta(event.get("delta") or "")
        elif t == "reasoning.available":
            self._add_thinking(event.get("text") or "Thinking...")
        elif t == "tool.started":
            self._add_tool_call(event.get("tool") or "tool", event.get("preview") or "", "running")
        elif t == "tool.completed":
            self._complete_tool_call(event.get("tool") or "", event.get("duration") or 0, bool(event.get("error")))
        elif t == "approval.request":
            self._add_approval(event)
        elif t == "run.completed":
            self._finalize_run(event)
        elif t == "run.failed":
            self._fail_run(event.get("error") or "Run failed")
        elif t == "run.cancelled":
            self._cancel_run()

    # ── Event handlers (mutate self._messages, emit row ops) ───
    def _append_delta(self, delta: str) -> None:
        if not delta:
            return
        with self._lock:
            if self._messages:
                idx = len(self._messages) - 1
                last = self._messages[idx]
                if last["type"] == "assistant" and last.get("isStreaming"):
                    last["content"] += delta
                    self.messageUpdated.emit(idx, {"content": last["content"]})
                    return
            for i in range(len(self._messages) - 1, -1, -1):
                if self._messages[i].get("isStreaming"):
                    self._messages[i]["isStreaming"] = False
                    self.messageUpdated.emit(i, {"isStreaming": False})
        self._append(
            db._row(
                "assistant",
                content=delta,
                isStreaming=True,
                timestamp=time.time(),
                startedAt=time.time(),
                usage={},
                duration=0,
            )
        )

    def _add_thinking(self, text: str) -> None:
        self._append(db._row("thinking", content=text, timestamp=time.time()))

    def _add_tool_call(self, tool: str, preview: str, status: str) -> None:
        self._append(
            db._row("tool_call", tool=tool, toolPreview=preview, toolStatus=status, timestamp=time.time())
        )

    def _complete_tool_call(self, tool: str, duration, error: bool) -> None:
        with self._lock:
            for i in range(len(self._messages) - 1, -1, -1):
                m = self._messages[i]
                if m["type"] == "tool_call" and m["tool"] == tool and m["toolStatus"] == "running":
                    m["toolStatus"] = "error" if error else "completed"
                    m["toolDuration"] = duration
                    self.messageUpdated.emit(i, {"toolStatus": m["toolStatus"], "toolDuration": duration})
                    return

    def _add_approval(self, event: dict) -> None:
        self._append(
            db._row(
                "approval",
                content=event.get("command") or event.get("message") or "Approval requested",
                timestamp=time.time(),
            )
        )

    def _finalize_run(self, event: dict) -> None:
        end = time.time()
        with self._lock:
            for i in range(len(self._messages) - 1, -1, -1):
                m = self._messages[i]
                if m.get("isStreaming"):
                    m["isStreaming"] = False
                    props = {"isStreaming": False, "duration": end - m.get("startedAt", end)}
                    if event.get("usage"):
                        m["usage"] = event["usage"]
                        props["usage"] = event["usage"]
                    self.messageUpdated.emit(i, props)
                    break
        if event.get("usage"):
            self._set_last_usage(event["usage"])
        if not self._currentSessionId and self._currentRunId:
            self._fetch_run_session_id(self._currentRunId)
        self._set_running(False)
        self.runCompleted.emit(event.get("output") or "")
        self.loadSessions()

    def _fail_run(self, error: str) -> None:
        self._seal_streaming(content="Error: " + error)
        self._set_running(False)
        self._set_last_error(error)
        self.runFailed.emit(error)

    def _cancel_run(self) -> None:
        self._seal_streaming()
        self._set_running(False)

    def _seal_streaming(self, content: str | None = None) -> None:
        with self._lock:
            for i in range(len(self._messages) - 1, -1, -1):
                if self._messages[i].get("isStreaming"):
                    self._messages[i]["isStreaming"] = False
                    props = {"isStreaming": False}
                    if content is not None:
                        self._messages[i]["content"] = content
                        props["content"] = content
                    self.messageUpdated.emit(i, props)
                    break

    def _fail_pending(self, msg: str) -> None:
        with self._lock:
            sealed = False
            for i in range(len(self._messages) - 1, -1, -1):
                m = self._messages[i]
                if m["type"] == "assistant" and m.get("isStreaming"):
                    m["content"] = "Error: " + msg
                    m["isStreaming"] = False
                    self.messageUpdated.emit(i, {"content": m["content"], "isStreaming": False})
                    sealed = True
                    break
        if not sealed:
            self._append(db._row("assistant", content="Error: " + msg, timestamp=time.time()))
        self._set_running(False)
        self._set_last_error(msg)
        self.runFailed.emit(msg)

    # ── Run session-id fetch ───────────────────────────────────
    def _fetch_run_session_id(self, run_id: str) -> None:
        def work():
            try:
                r = self._client.get(
                    f"{self._apiBaseUrl}/v1/runs/{run_id}", headers=self._headers(), timeout=5.0
                )
                sid = r.json().get("session_id")
                if sid and not self._currentSessionId:
                    self._set_current_session(sid)
            except Exception:
                pass

        self._spawn(work)

    # ───────────────────────────────────────────────────────────
    #  Stop / approval
    # ───────────────────────────────────────────────────────────
    @Slot()
    def stopRun(self) -> None:
        if not self._currentRunId:
            return
        run_id = self._currentRunId
        self._sseStop.set()
        self._set_running(False)
        self._cancel_run()
        self._spawn(
            lambda: self._post_quiet(f"{self._apiBaseUrl}/v1/runs/{run_id}/stop")
        )

    @Slot(str)
    def resolveApproval(self, choice: str) -> None:
        if not self._currentRunId:
            return
        run_id = self._currentRunId
        self._spawn(
            lambda: self._post_quiet(
                f"{self._apiBaseUrl}/v1/runs/{run_id}/approval",
                json_body={"choice": choice},
            )
        )

    def _post_quiet(self, url: str, json_body: dict | None = None) -> None:
        try:
            self._client.post(
                url,
                headers=self._headers(json_body=json_body is not None),
                json=json_body,
                timeout=5.0,
            )
        except Exception:
            pass

    def _detach_run(self) -> None:
        """Stop listening to the current run without cancelling it server-side."""
        self._accepting = False
        self._sseStop.set()
        self._set_running(False)
        self._set_current_run("")

    # ───────────────────────────────────────────────────────────
    #  Settings update (from the SettingsPanel)
    # ───────────────────────────────────────────────────────────
    @Slot(str, str, str, str)
    def updateSettings(self, api_base_url: str, api_key: str, hermes_home: str, model: str) -> None:
        self._apiBaseUrl = api_base_url
        self._apiKey = api_key
        self._hermesHome = hermes_home
        self._selectedModel = model
        self._envApiKey = ""
        self._discover_env_key()
        self._save_settings()
        self.configChanged.emit()
        self.checkHealth()
        self.loadSessions()
        self.loadWelcomeInfo()

    # ───────────────────────────────────────────────────────────
    #  Append helper
    # ───────────────────────────────────────────────────────────
    def _append(self, row: dict) -> None:
        with self._lock:
            self._messages.append(row)
        self.messageAppended.emit(row)

    # ───────────────────────────────────────────────────────────
    #  Property setters (thread-safe-ish: only emit on change)
    # ───────────────────────────────────────────────────────────
    def _set_connected(self, v: bool):
        if v != self._connected:
            self._connected = v
            self.connectedChanged.emit()

    def _set_current_session(self, v: str):
        if v != self._currentSessionId:
            self._currentSessionId = v
            self.currentSessionIdChanged.emit()

    def _set_current_model(self, v: str):
        if v != self._currentModel:
            self._currentModel = v
            self.currentModelChanged.emit()

    def _set_running(self, v: bool):
        if v != self._isRunning:
            self._isRunning = v
            self.isRunningChanged.emit()

    def _set_current_run(self, v: str):
        if v != self._currentRunId:
            self._currentRunId = v
            self.currentRunIdChanged.emit()

    def _set_last_usage(self, v: dict):
        self._lastUsage = v
        self.lastUsageChanged.emit()

    def _set_last_error(self, v: str):
        self._lastError = v
        self.lastErrorChanged.emit()

    def _set_welcome(self, v: dict):
        self._welcomeInfo = v
        self.welcomeInfoChanged.emit()

    # ───────────────────────────────────────────────────────────
    #  Qt Properties
    # ───────────────────────────────────────────────────────────
    apiBaseUrl = Property(str, lambda s: s._apiBaseUrl, notify=configChanged)
    apiKey = Property(str, lambda s: s._apiKey, notify=configChanged)
    hermesHome = Property(str, lambda s: s._hermesHome, notify=configChanged)
    selectedModel = Property(str, lambda s: s._selectedModel, notify=configChanged)

    connected = Property(bool, lambda s: s._connected, notify=connectedChanged)
    currentSessionId = Property(str, lambda s: s._currentSessionId, notify=currentSessionIdChanged)
    currentModel = Property(str, lambda s: s._currentModel, notify=currentModelChanged)
    isRunning = Property(bool, lambda s: s._isRunning, notify=isRunningChanged)
    currentRunId = Property(str, lambda s: s._currentRunId, notify=currentRunIdChanged)
    lastUsage = Property("QVariant", lambda s: s._lastUsage, notify=lastUsageChanged)
    lastError = Property(str, lambda s: s._lastError, notify=lastErrorChanged)
    welcomeInfo = Property("QVariant", lambda s: s._welcomeInfo, notify=welcomeInfoChanged)

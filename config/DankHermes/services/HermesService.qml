import QtQuick
import Quickshell.Io
import qs.Common

Item {
    id: root

    // ── Configuration ──────────────────────────────────────────
    property string apiBaseUrl: "http://127.0.0.1:8642"
    property string hermesHome: "~/.hermes"
    property string apiKey: ""
    property string selectedModel: ""

    // ── Public State ───────────────────────────────────────────
    property bool connected: false
    property string currentSessionId: ""
    property string currentRunId: ""
    property bool isRunning: false
    property string currentModel: ""
    property var lastUsage: ({})
    property string lastError: ""

    // ── Data Models ────────────────────────────────────────────
    property alias sessionList: _sessionList
    property alias messageList: _messageList

    ListModel { id: _sessionList }
    ListModel { id: _messageList; dynamicRoles: true }

    // ── Signals ────────────────────────────────────────────────
    signal runStarted()
    signal runCompleted(string output)
    signal runFailed(string error)

    // ── Build auth header value (empty string when no key) ─────
    readonly property string _authVal: apiKey ? "Authorization: Bearer " + apiKey : ""

    // ── Resolve sibling python helper scripts ──────────────────
    readonly property string _sessionsScript: Qt.resolvedUrl("load_sessions.py").toString().replace(/^file:\/\//, "")
    readonly property string _messagesScript: Qt.resolvedUrl("load_messages.py").toString().replace(/^file:\/\//, "")

    // ═══════════════════════════════════════════════════════════
    //  HEALTH CHECK
    // ═══════════════════════════════════════════════════════════

    Timer {
        id: healthTimer
        interval: 15000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: checkHealth()
    }

    Process {
        id: healthProcess
        running: false
        property string targetUrl: ""
        command: ["sh", "-c", "curl -sS --connect-timeout 2 --max-time 3 ${HERMES_AUTH:+-H \"$HERMES_AUTH\"} \"$TARGET_URL\""]
        environment: ({ "TARGET_URL": targetUrl, "HERMES_AUTH": root._authVal })
        stdout: SplitParser {
            onRead: data => {
                try {
                    const resp = JSON.parse(data)
                    root.connected = (resp.status === "ok" || resp.status === "healthy")
                    if (resp.model) root.currentModel = resp.model
                } catch (e) {
                    root.connected = false
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.connected = false
        }
    }

    function checkHealth() {
        healthProcess.targetUrl = apiBaseUrl + "/health"
        healthProcess.running = true
    }

    // ═══════════════════════════════════════════════════════════
    //  SESSION LIST (python3 → state.db)
    // ═══════════════════════════════════════════════════════════

    Process {
        id: sessionProcess
        running: false
        property string dbPath: ""
        command: ["python3", root._sessionsScript]
        environment: ({ "DB": dbPath, "LIMIT": "30" })
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("DankHermes: session raw output length:", text.length)
                try {
                    const sessions = JSON.parse(text)
                    console.log("DankHermes: parsed", sessions.length, "sessions")
                    _sessionList.clear()
                    for (let i = 0; i < sessions.length; i++) {
                        const s = sessions[i]
                        console.log("DankHermes: session", i, "id=", s.id, "title=", s.title)
                        _sessionList.append({
                            "sessionId": String(s.id || ""),
                            "title": String(s.title || "Untitled"),
                            "modelName": String(s.model || ""),
                            "startedAt": Number(s.started_at || 0),
                            "messageCount": Number(s.message_count || 0)
                        })
                    }
                } catch (e) {
                    console.warn("DankHermes: session parse error:", e, "text:", text.substring(0, 200))
                }
            }
        }
        stderr: SplitParser {
            onRead: data => console.warn("DankHermes: session stderr:", data)
        }
        onExited: (code, status) => {
            if (code !== 0) console.warn("DankHermes: session process exited with code", code)
        }
    }

    function loadSessions() {
        console.log("DankHermes: loadSessions() called, dbPath=", hermesHome + "/state.db")
        sessionProcess.dbPath = hermesHome + "/state.db"
        sessionProcess.running = true
    }

    // ═══════════════════════════════════════════════════════════
    //  LOAD MESSAGES (python3 → state.db)
    // ═══════════════════════════════════════════════════════════

    Process {
        id: messageProcess
        running: false
        property string dbPath: ""
        property string sessionId: ""
        command: ["python3", root._messagesScript]
        environment: ({ "DB": dbPath, "SID": sessionId })
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("DankHermes: message raw output length:", text.length, "for session:", messageProcess.sessionId)
                try {
                    const messages = JSON.parse(text)
                    console.log("DankHermes: parsed", messages.length, "messages")
                    _messageList.clear()
                    for (const m of messages) {
                        const role = m.role || "assistant"

                        // Tool-result rows render as a collapsible pill so the
                        // raw JSON doesn't dominate the chat by default.
                        if (role === "tool") {
                            _messageList.append({
                                "type": "tool_result",
                                "content": m.content || "",
                                "tool": m.tool_name || "tool",
                                "toolPreview": "", "toolStatus": "completed",
                                "toolDuration": 0, "isStreaming": false,
                                "timestamp": m.timestamp || 0,
                                "expanded": false
                            })
                            continue
                        }

                        let msgType = role === "user" ? "user" : "assistant"

                        const reasoningText = m.reasoning || m.reasoning_content || ""
                        if (reasoningText && role === "assistant") {
                            _messageList.append({
                                "type": "thinking",
                                "content": reasoningText.substring(0, 500),
                                "tool": "", "toolPreview": "", "toolStatus": "",
                                "toolDuration": 0, "isStreaming": false,
                                "timestamp": (m.timestamp || 0) - 0.001
                            })
                        }

                        if (m.tool_calls && role === "assistant") {
                            try {
                                const calls = JSON.parse(m.tool_calls)
                                for (const call of calls) {
                                    _messageList.append({
                                        "type": "tool_call",
                                        "content": "",
                                        "tool": call.function && call.function.name ? call.function.name : (m.tool_name || "tool"),
                                        "toolPreview": (call.function && call.function.arguments ? call.function.arguments : "").substring(0, 120),
                                        "toolStatus": "completed",
                                        "toolDuration": 0, "isStreaming": false,
                                        "timestamp": m.timestamp || 0
                                    })
                                }
                            } catch (e) {}
                        }

                        const content = m.content || ""
                        if (!content && (m.tool_calls || m.tool_name)) continue

                        _messageList.append({
                            "type": msgType,
                            "content": content,
                            "tool": "", "toolPreview": "", "toolStatus": "",
                            "toolDuration": 0, "isStreaming": false,
                            "timestamp": m.timestamp || 0
                        })
                    }
                } catch (e) {
                    console.warn("DankHermes: message parse error:", e)
                }
            }
        }
        stderr: SplitParser {
            onRead: data => console.warn("DankHermes: message stderr:", data)
        }
        onExited: (code, status) => {
            if (code !== 0) console.warn("DankHermes: message process exited with code", code)
        }
    }

    function loadMessages(sessionId) {
        console.log("DankHermes: loadMessages called with sessionId:", sessionId)
        currentSessionId = sessionId
        messageProcess.dbPath = hermesHome + "/state.db"
        messageProcess.sessionId = sessionId
        messageProcess.running = true
    }

    // ═══════════════════════════════════════════════════════════
    //  NEW CHAT
    // ═══════════════════════════════════════════════════════════

    function newChat() {
        currentSessionId = ""
        currentRunId = ""
        _messageList.clear()
    }

    // ═══════════════════════════════════════════════════════════
    //  SEND MESSAGE → POST /v1/runs
    // ═══════════════════════════════════════════════════════════

    Process {
        id: runStartProcess
        running: false
        property string requestBody: ""
        property string targetUrl: ""
        command: ["sh", "-c",
            "curl -sS --connect-timeout 5 --max-time 15 -X POST -H 'Content-Type: application/json' ${HERMES_AUTH:+-H \"$HERMES_AUTH\"} -d \"$BODY\" \"$TARGET_URL\""
        ]
        environment: ({
            "BODY": requestBody,
            "TARGET_URL": targetUrl,
            "HERMES_AUTH": root._authVal
        })

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const resp = JSON.parse(text)
                    if (resp.run_id) {
                        root.currentRunId = resp.run_id
                        root.isRunning = true
                        root.runStarted()
                        subscribeEvents(resp.run_id)
                    } else {
                        const msg = resp.error
                            ? ((resp.error.message ? resp.error.message : "") || (typeof resp.error === "string" ? resp.error : "Unknown error"))
                            : "Gateway returned no run_id"
                        root._failPendingSend(msg)
                    }
                } catch (e) {
                    const snippet = (text || "").substring(0, 200) || "empty response"
                    root._failPendingSend("Failed to start run: " + snippet)
                }
            }
        }

        // No onExited handler — StdioCollector.onStreamFinished fires on EOF and
        // covers both success and failure paths, so handling exit here would
        // double-report the error.
    }

    function _failPendingSend(msg) {
        root.lastError = msg
        for (let i = _messageList.count - 1; i >= 0; i--) {
            const m = _messageList.get(i)
            if (m.type === "assistant" && m.isStreaming) {
                _messageList.setProperty(i, "content", "Error: " + msg)
                _messageList.setProperty(i, "isStreaming", false)
                root.isRunning = false
                root.runFailed(msg)
                return
            }
        }
        _messageList.append({
            "type": "assistant",
            "content": "Error: " + msg,
            "tool": "", "toolPreview": "", "toolStatus": "",
            "toolDuration": 0, "isStreaming": false,
            "timestamp": Date.now() / 1000
        })
        root.isRunning = false
        root.runFailed(msg)
    }

    function _buildConversationHistory() {
        const history = []
        for (let i = 0; i < _messageList.count; i++) {
            const msg = _messageList.get(i)
            if ((msg.type === "user" || msg.type === "assistant") && msg.content && msg.content.trim()) {
                history.push({
                    role: msg.type === "user" ? "user" : "assistant",
                    content: msg.content
                })
            }
        }
        return history
    }

    function sendMessage(text) {
        if (isRunning || !text.trim()) return

        const history = _buildConversationHistory()

        _messageList.append({
            "type": "user", "content": text,
            "tool": "", "toolPreview": "", "toolStatus": "",
            "toolDuration": 0, "isStreaming": false,
            "timestamp": Date.now() / 1000
        })

        _messageList.append({
            "type": "assistant", "content": "",
            "tool": "", "toolPreview": "", "toolStatus": "",
            "toolDuration": 0, "isStreaming": true,
            "timestamp": Date.now() / 1000,
            "startedAt": Date.now() / 1000,
            "usage": ({}),
            "duration": 0
        })

        const reqBody = {
            input: text,
            session_id: currentSessionId || undefined,
            conversation_history: history
        }
        if (selectedModel) reqBody.model = selectedModel
        const body = JSON.stringify(reqBody)

        runStartProcess.requestBody = body
        runStartProcess.targetUrl = apiBaseUrl + "/v1/runs"
        runStartProcess.running = true
    }

    // ═══════════════════════════════════════════════════════════
    //  SSE EVENT STREAM → GET /v1/runs/{id}/events
    // ═══════════════════════════════════════════════════════════

    property var _sseProcess: null

    Component {
        id: sseProcessComponent

        Process {
            property string eventsUrl: ""

            command: ["sh", "-c",
                "curl -sS -N --connect-timeout 5 --max-time 300 ${HERMES_AUTH:+-H \"$HERMES_AUTH\"} \"$EVENTS_URL\""
            ]
            environment: ({
                "EVENTS_URL": eventsUrl,
                "HERMES_AUTH": root._authVal
            })

            stdout: SplitParser {
                onRead: data => root._handleSSELine(data)
            }

            onExited: (code, status) => {
                root.isRunning = false
                for (let i = _messageList.count - 1; i >= 0; i--) {
                    if (_messageList.get(i).isStreaming) {
                        _messageList.setProperty(i, "isStreaming", false)
                        break
                    }
                }
                destroy()
            }
        }
    }

    function subscribeEvents(runId) {
        if (_sseProcess) {
            _sseProcess.running = false
            try { _sseProcess.destroy() } catch (e) {}
        }

        _sseProcess = sseProcessComponent.createObject(root, {
            eventsUrl: apiBaseUrl + "/v1/runs/" + runId + "/events"
        })
        if (_sseProcess) _sseProcess.running = true
    }

    // ── SSE Line Parser ────────────────────────────────────────

    function _handleSSELine(line) {
        const trimmed = line.trim()
        if (!trimmed || trimmed.startsWith(":")) return
        if (!trimmed.startsWith("data: ")) return

        try {
            const event = JSON.parse(trimmed.substring(6))
            _handleEvent(event)
        } catch (e) {}
    }

    // ── Event Dispatcher ───────────────────────────────────────

    function _handleEvent(event) {
        const type = event.event
        if (!type) return

        switch (type) {
        case "message.delta":      _appendDelta(event.delta || ""); break
        case "reasoning.available": _addThinking(event.text || "Thinking..."); break
        case "tool.started":       _addToolCall(event.tool || "tool", event.preview || "", "running"); break
        case "tool.completed":     _completeToolCall(event.tool || "", event.duration || 0, event.error || false); break
        case "approval.request":   _addApproval(event); break
        case "run.completed":      _finalizeRun(event); break
        case "run.failed":         _failRun(event.error || "Run failed"); break
        case "run.cancelled":      _cancelRun(); break
        }
    }

    // ── Event Handlers ─────────────────────────────────────────

    function _appendDelta(delta) {
        if (!delta) return
        for (let i = _messageList.count - 1; i >= 0; i--) {
            const msg = _messageList.get(i)
            if (msg.type === "assistant" && msg.isStreaming) {
                _messageList.setProperty(i, "content", msg.content + delta)
                return
            }
        }
        // Fallback: no streaming assistant found, append new
        _messageList.append({
            "type": "assistant", "content": delta,
            "tool": "", "toolPreview": "", "toolStatus": "",
            "toolDuration": 0, "isStreaming": true,
            "timestamp": Date.now() / 1000
        })
    }

    function _addThinking(text) {
        _messageList.append({
            "type": "thinking", "content": text,
            "tool": "", "toolPreview": "", "toolStatus": "",
            "toolDuration": 0, "isStreaming": false,
            "timestamp": Date.now() / 1000
        })
    }

    function _addToolCall(tool, preview, status) {
        _messageList.append({
            "type": "tool_call", "content": "",
            "tool": tool, "toolPreview": preview, "toolStatus": status,
            "toolDuration": 0, "isStreaming": false,
            "timestamp": Date.now() / 1000
        })
    }

    function _completeToolCall(tool, duration, error) {
        for (let i = _messageList.count - 1; i >= 0; i--) {
            const msg = _messageList.get(i)
            if (msg.type === "tool_call" && msg.tool === tool && msg.toolStatus === "running") {
                _messageList.setProperty(i, "toolStatus", error ? "error" : "completed")
                _messageList.setProperty(i, "toolDuration", duration)
                return
            }
        }
    }

    function _addApproval(event) {
        _messageList.append({
            "type": "approval",
            "content": event.command || event.message || "Approval requested",
            "tool": "", "toolPreview": "", "toolStatus": "",
            "toolDuration": 0, "isStreaming": false,
            "timestamp": Date.now() / 1000
        })
    }

    function _finalizeRun(event) {
        const endTime = Date.now() / 1000
        for (let i = _messageList.count - 1; i >= 0; i--) {
            const m = _messageList.get(i)
            if (m.isStreaming) {
                _messageList.setProperty(i, "isStreaming", false)
                _messageList.setProperty(i, "duration", endTime - (m.startedAt || endTime))
                if (event.usage) _messageList.setProperty(i, "usage", event.usage)
                break
            }
        }
        if (event.usage) lastUsage = event.usage
        if (!currentSessionId && currentRunId) _fetchRunSessionId(currentRunId)
        root.isRunning = false
        root.runCompleted(event.output || "")
        Qt.callLater(loadSessions)
    }

    function _failRun(error) {
        for (let i = _messageList.count - 1; i >= 0; i--) {
            if (_messageList.get(i).isStreaming) {
                _messageList.setProperty(i, "content", "Error: " + error)
                _messageList.setProperty(i, "isStreaming", false)
                break
            }
        }
        root.isRunning = false
        root.lastError = error
        root.runFailed(error)
    }

    function _cancelRun() {
        for (let i = _messageList.count - 1; i >= 0; i--) {
            if (_messageList.get(i).isStreaming) {
                _messageList.setProperty(i, "isStreaming", false)
                break
            }
        }
        root.isRunning = false
    }

    // ── Fetch session_id from run status ───────────────────────

    Process {
        id: runStatusProcess
        running: false
        property string targetUrl: ""
        command: ["sh", "-c",
            "curl -sS --connect-timeout 3 --max-time 5 ${HERMES_AUTH:+-H \"$HERMES_AUTH\"} \"$TARGET_URL\""
        ]
        environment: ({ "TARGET_URL": targetUrl, "HERMES_AUTH": root._authVal })
        stdout: SplitParser {
            onRead: data => {
                try {
                    const resp = JSON.parse(data)
                    if (resp.session_id && !root.currentSessionId) {
                        root.currentSessionId = resp.session_id
                    }
                } catch (e) {}
            }
        }
    }

    function _fetchRunSessionId(runId) {
        runStatusProcess.targetUrl = apiBaseUrl + "/v1/runs/" + runId
        runStatusProcess.running = true
    }

    // ═══════════════════════════════════════════════════════════
    //  STOP RUN → POST /v1/runs/{id}/stop
    // ═══════════════════════════════════════════════════════════

    Process {
        id: stopProcess
        running: false
        property string targetUrl: ""
        command: ["sh", "-c",
            "curl -sS --connect-timeout 3 --max-time 5 -X POST ${HERMES_AUTH:+-H \"$HERMES_AUTH\"} \"$TARGET_URL\""
        ]
        environment: ({ "TARGET_URL": targetUrl, "HERMES_AUTH": root._authVal })
    }

    function stopRun() {
        if (!currentRunId) return
        stopProcess.targetUrl = apiBaseUrl + "/v1/runs/" + currentRunId + "/stop"
        stopProcess.running = true
        if (_sseProcess) _sseProcess.running = false
        root.isRunning = false
        _cancelRun()
    }

    // ═══════════════════════════════════════════════════════════
    //  RESOLVE APPROVAL → POST /v1/runs/{id}/approval
    // ═══════════════════════════════════════════════════════════

    Process {
        id: approvalProcess
        running: false
        property string requestBody: ""
        property string targetUrl: ""
        command: ["sh", "-c",
            "curl -sS --connect-timeout 3 --max-time 5 -X POST -H 'Content-Type: application/json' ${HERMES_AUTH:+-H \"$HERMES_AUTH\"} -d \"$BODY\" \"$TARGET_URL\""
        ]
        environment: ({
            "BODY": requestBody,
            "TARGET_URL": targetUrl,
            "HERMES_AUTH": root._authVal
        })
    }

    function resolveApproval(choice) {
        if (!currentRunId) return
        approvalProcess.requestBody = JSON.stringify({ choice: choice })
        approvalProcess.targetUrl = apiBaseUrl + "/v1/runs/" + currentRunId + "/approval"
        approvalProcess.running = true

        for (let i = _messageList.count - 1; i >= 0; i--) {
            if (_messageList.get(i).type === "approval") {
                _messageList.setProperty(i, "toolStatus", choice)
                break
            }
        }
    }

    // ── Initial load ───────────────────────────────────────────
    Component.onCompleted: {
        console.info("DankHermes: HermesService created")
        checkHealth()
        loadSessions()
    }
}

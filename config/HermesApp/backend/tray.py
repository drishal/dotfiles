"""System tray icon + desktop notifications.

Gives the app a presence outside its window: a robot tray icon with quick
actions, and a notification when a run finishes while the window isn't focused —
so you can fire off a long task, switch away, and get pinged when it's done.

Requires a StatusNotifierItem host (the user's bar tray). Degrades to a no-op
if no system tray is available.
"""
from __future__ import annotations

from PySide6.QtCore import QObject, Qt
from PySide6.QtGui import (
    QAction,
    QColor,
    QFont,
    QFontDatabase,
    QIcon,
    QPainter,
    QPixmap,
)
from PySide6.QtWidgets import QMenu, QSystemTrayIcon


def make_icon(font_path: str, glyph: str = "smart_toy", color: str = "#d4be98") -> QIcon:
    """Render a Material Symbols ligature to a QIcon (matches the in-app robot)."""
    fid = QFontDatabase.addApplicationFont(font_path)
    families = QFontDatabase.applicationFontFamilies(fid)
    pm = QPixmap(64, 64)
    pm.fill(Qt.transparent)
    p = QPainter(pm)
    if families:
        f = QFont(families[0])
        f.setPixelSize(54)
        p.setFont(f)
    p.setPen(QColor(color))
    p.drawText(pm.rect(), Qt.AlignCenter, glyph)
    p.end()
    return QIcon(pm)


class Tray(QObject):
    def __init__(self, app, window, backend, icon: QIcon) -> None:
        super().__init__()
        self._app = app
        self._window = window
        self._backend = backend
        self._tray: QSystemTrayIcon | None = None

        if not QSystemTrayIcon.isSystemTrayAvailable():
            return

        self._tray = QSystemTrayIcon(icon, self)
        self._tray.setToolTip("Hermes Agent")

        menu = QMenu()
        a_show = QAction("Show / Hide", self)
        a_show.triggered.connect(self._toggle_window)
        a_new = QAction("New Chat", self)
        a_new.triggered.connect(self._new_chat)
        a_quit = QAction("Quit", self)
        a_quit.triggered.connect(self._app.quit)
        menu.addAction(a_show)
        menu.addAction(a_new)
        menu.addSeparator()
        menu.addAction(a_quit)
        self._tray.setContextMenu(menu)
        self._tray.activated.connect(self._on_activated)
        self._tray.show()

        backend.runCompleted.connect(self._on_completed)
        backend.runFailed.connect(self._on_failed)

    # ── Window helpers ─────────────────────────────────────────
    def _show_window(self) -> None:
        self._window.show()
        self._window.raise_()
        self._window.requestActivate()

    def _toggle_window(self) -> None:
        if self._window.isVisible() and self._window.isActive():
            self._window.hide()
        else:
            self._show_window()

    def _new_chat(self) -> None:
        self._backend.newChat()
        self._show_window()

    def _on_activated(self, reason) -> None:
        if reason in (QSystemTrayIcon.Trigger, QSystemTrayIcon.DoubleClick):
            self._show_window()

    # ── Notifications (only when the window isn't focused) ─────
    def _on_completed(self, output: str) -> None:
        if not self._tray or self._window.isActive():
            return
        body = (output or "").strip()
        body = (body[:140] + "…") if len(body) > 140 else (body or "Run completed")
        self._tray.showMessage("Hermes finished", body, QSystemTrayIcon.Information, 5000)

    def _on_failed(self, error: str) -> None:
        if not self._tray or self._window.isActive():
            return
        self._tray.showMessage(
            "Hermes run failed", error or "Run failed", QSystemTrayIcon.Critical, 6000
        )

#!/usr/bin/env python3
"""Hermes desktop app — PySide6 entry point.

Loads the QML UI (unchanged from the Quickshell version) against a native Python
backend. The Quickshell runtime, curl/python3 subprocesses, and DMS dependency
are gone; this is a plain Qt Quick application.

Run:  python3 main.py     (with PySide6 + httpx + pygments on the path)
"""
from __future__ import annotations

import json
import os
import signal
import sys

from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

from backend.hermes_backend import HermesBackend
from backend.platform_bridge import Platform
from backend.tray import Tray, make_icon

APP_DIR = os.path.dirname(os.path.abspath(__file__))
FONT_PATH = os.path.join(APP_DIR, "assets", "fonts", "MaterialSymbolsRounded.ttf")
COLORS_PATH = os.path.expanduser("~/.config/HermesApp/colors.json")


def load_stylix_colors():
    """The home-manager module generates this from the active stylix scheme.
    Absent (e.g. running standalone) → None, and Theme keeps its gruvbox
    defaults."""
    try:
        with open(COLORS_PATH) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def main() -> int:
    # Ctrl-C from a terminal should quit cleanly.
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QApplication(sys.argv)
    app.setApplicationName("Hermes Agent")
    app.setDesktopFileName("hermes-app")
    # Window-close quits even though a tray icon keeps an event source alive.
    app.setQuitOnLastWindowClosed(True)

    icon = make_icon(FONT_PATH)
    app.setWindowIcon(icon)

    backend = HermesBackend()
    platform = Platform()

    engine = QQmlApplicationEngine()
    # Lets `import qs.Common` / `import qs.Widgets` resolve to the bundled
    # QtQuick modules under ./qs.
    engine.addImportPath(APP_DIR)

    ctx = engine.rootContext()
    ctx.setContextProperty("stylixColors", load_stylix_colors())
    ctx.setContextProperty("hermesBackend", backend)
    ctx.setContextProperty("Platform", platform)

    engine.load(QUrl.fromLocalFile(os.path.join(APP_DIR, "qml", "Window.qml")))
    if not engine.rootObjects():
        print("Failed to load QML", file=sys.stderr)
        return 1

    window = engine.rootObjects()[0]
    tray = Tray(app, window, backend, icon)  # noqa: F841 — kept alive by ref

    # Initial data loads now that QML signal handlers are connected.
    backend.start()

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())

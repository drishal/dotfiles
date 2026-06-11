"""Platform bridge — desktop integration the QML components need.

Replaces the per-component subprocess hacks (`dms clipboard copy`, `dms chroma`,
`wl-paste`) with in-process Qt + Pygments. All methods run on the GUI thread
(invoked synchronously from QML), which is required for clipboard access.
"""
from __future__ import annotations

import os
import time

from PySide6.QtCore import QObject, Slot
from PySide6.QtGui import QGuiApplication

try:
    from pygments import highlight as _pyg_highlight
    from pygments.formatters import HtmlFormatter
    from pygments.lexers import get_lexer_by_name
    from pygments.util import ClassNotFound

    _HAVE_PYGMENTS = True
except ImportError:  # pragma: no cover
    _HAVE_PYGMENTS = False


class Platform(QObject):
    @Slot(str)
    def copyToClipboard(self, text: str) -> None:
        cb = QGuiApplication.clipboard()
        if cb is not None:
            cb.setText(text)

    @Slot(result=str)
    def pasteImage(self) -> str:
        """If the clipboard holds an image, save it to /tmp and return the path;
        otherwise return "" (the common text-paste case)."""
        cb = QGuiApplication.clipboard()
        if cb is None:
            return ""
        img = cb.image()
        if img is None or img.isNull():
            return ""
        path = f"/tmp/hermes-paste-{int(time.time() * 1000)}.png"
        return path if img.save(path, "PNG") else ""

    @Slot(str, str, result=str)
    def highlightHtml(self, code: str, lang: str) -> str:
        """Monokai-styled HTML for a code block (inline styles, no class refs).

        Returns the same monokai palette the old `dms chroma` path emitted, so
        CodeBlock's theme remap keeps working. Empty string ⇒ plain fallback.
        """
        if not _HAVE_PYGMENTS or not code:
            return ""
        try:
            lexer = get_lexer_by_name(lang or "text")
        except ClassNotFound:
            try:
                lexer = get_lexer_by_name("text")
            except ClassNotFound:
                return ""
        formatter = HtmlFormatter(noclasses=True, nowrap=True, style="monokai")
        try:
            inner = _pyg_highlight(code, lexer, formatter)
        except Exception:
            return ""
        return f"<pre>{inner}</pre>"

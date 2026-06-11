import QtQuick
import qs.Common

// Minimal stand-in for DMS's StyledText. The chat components set color/font
// explicitly in almost every use; this just supplies sensible defaults and
// crisp native rendering so nothing has to change.
Text {
    color: Theme.surfaceText
    font.pixelSize: Theme.fontSizeMedium
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
}

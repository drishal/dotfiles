import QtQuick

// Thin coordinator between the Python HermesBackend and the QML views.
//
// The views were written against a QML service that owned ListModels and a
// property/signal/method surface. This preserves exactly that surface but
// delegates all work to `backend` (the native HermesBackend), mirroring its
// emitted row-ops into the ListModels. Nothing in components/ had to change.
Item {
    id: root

    property var backend: null

    // ── Config mirror (read by SettingsPanel) ──────────────────
    readonly property string apiBaseUrl: backend ? backend.apiBaseUrl : ""
    readonly property string apiKey: backend ? backend.apiKey : ""
    readonly property string hermesHome: backend ? backend.hermesHome : ""
    readonly property string selectedModel: backend ? backend.selectedModel : ""

    // ── Runtime state mirror ───────────────────────────────────
    readonly property bool connected: backend ? backend.connected : false
    readonly property string currentSessionId: backend ? backend.currentSessionId : ""
    readonly property string currentModel: backend ? backend.currentModel : ""
    readonly property bool isRunning: backend ? backend.isRunning : false
    readonly property var lastUsage: backend ? backend.lastUsage : ({})
    readonly property var welcomeInfo: backend ? backend.welcomeInfo : ({})

    // ── Models the views bind to ───────────────────────────────
    property alias sessionList: _sessionList
    property alias messageList: _messageList
    ListModel { id: _sessionList }
    ListModel { id: _messageList; dynamicRoles: true }

    // ── Signals the views connect to ───────────────────────────
    signal runStarted()
    signal runCompleted(string output)
    signal runFailed(string error)

    // ── Methods the views call (forward to backend) ────────────
    function loadSessions() { if (backend) backend.loadSessions() }
    function loadMessages(sessionId) { if (backend) backend.loadMessages(sessionId) }
    function newChat() { if (backend) backend.newChat() }
    function sendMessage(text) { if (backend) backend.sendMessage(text) }
    function stopRun() { if (backend) backend.stopRun() }
    function resolveApproval(choice) { if (backend) backend.resolveApproval(choice) }

    Connections {
        target: root.backend

        function onSessionsReset(list) {
            _sessionList.clear()
            for (let i = 0; i < list.length; i++)
                _sessionList.append(list[i])
        }
        function onMessagesReset(list) {
            _messageList.clear()
            for (let i = 0; i < list.length; i++)
                _messageList.append(list[i])
        }
        function onMessageAppended(msg) {
            _messageList.append(msg)
        }
        function onMessageUpdated(row, props) {
            if (row < 0 || row >= _messageList.count) return
            for (let k in props)
                _messageList.setProperty(row, k, props[k])
        }
        function onRunStarted() { root.runStarted() }
        function onRunCompleted(output) { root.runCompleted(output) }
        function onRunFailed(error) { root.runFailed(error) }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets

/**
 * AIAssistantView - Main chat interface (MVVM refactored)
 * Uses ChatViewModel for UI state and commands
 */
Item {
    id: root

    implicitWidth: 480
    implicitHeight: 640

    required property var viewModel
    required property var settingsViewModel
    required property var providerService
    required property var sessionService

    signal hideRequested

    property real nowMs: Date.now()
    readonly property real panelTransparency: SettingsData.popupTransparency
    readonly property int streamElapsedSeconds: (viewModel.isStreaming && (streamStartedAtMs ?? 0) > 0)
        ? Math.max(0, Math.floor((nowMs - streamStartedAtMs) / 1000)) : 0

    property real streamStartedAtMs: 0

    onVisibleChanged: {
        if (!visible) {
            viewModel.closeMenus();
        }
    }

    Component.onCompleted: {
        console.log("[AIAssistantView] Initialized with MVVM architecture");
    }


    Timer {
        id: hintResetTimer
        interval: 2500
        onTriggered: viewModel.transientHint = ""
    }


    Timer {
        id: streamTimer
        interval: 100
        running: viewModel.isStreaming
        repeat: true
        onTriggered: nowMs = Date.now()
    }


    ColumnLayout {
        anchors.fill: parent
        spacing: 0


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: Theme.surface
            border.color: Theme.outline
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                StyledText {
                    text: viewModel.getActiveProviderName()
                    font.bold: true
                    Layout.fillWidth: true
                }

                DankButton {
                    text: "⚙"
                    width: 32
                    height: 32
                    onClicked: viewModel.toggleSettingsMenu()
                }

                DankButton {
                    text: "⋮"
                    width: 32
                    height: 32
                    onClicked: viewModel.toggleOverflowMenu()
                }
            }
        }


        MessageList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            messages: viewModel.messages
            onRetryRequested: (messageId) => viewModel.retry()
            onRegenerateRequested: (messageId) => viewModel.regenerate(messageId)
            onCopyRequested: (messageId) => viewModel.copyMessage(messageId)
        }


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: viewModel.transientHint ? 32 : 0
            color: Theme.accentColor
            visible: viewModel.transientHint.length > 0

            StyledText {
                anchors.centerIn: parent
                text: viewModel.transientHint
                color: "white"
            }
        }


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Theme.surface
            border.color: Theme.outline
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                DankTextField {
                    id: composer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Type your message..."
                    text: viewModel.composerText
                    onTextChanged: viewModel.composerText = text
                    enabled: !viewModel.isStreaming

                    Keys.onReturnPressed: {
                        if (event.modifiers & Qt.ShiftModifier) {
                            // Shift+Enter: new line
                            text += "\n";
                        } else {
                            // Enter: send
                            viewModel.sendMessage();
                        }
                    }

                    Keys.onEscapePressed: {
                        if (viewModel.isStreaming) {
                            viewModel.cancel();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    DankButton {
                        text: viewModel.isStreaming ? "Cancel" : "Send"
                        Layout.fillWidth: true
                        enabled: viewModel.composerText.trim().length > 0 || viewModel.isStreaming
                        onClicked: {
                            if (viewModel.isStreaming) {
                                viewModel.cancel();
                            } else {
                                viewModel.sendMessage();
                            }
                        }
                    }

                    DankButton {
                        text: "Clear"
                        width: 60
                        enabled: viewModel.hasMessages && !viewModel.isStreaming
                        onClicked: viewModel.clearHistory()
                    }
                }
            }
        }
    }


    Rectangle {
        id: settingsPopup
        visible: viewModel.showSettingsMenu
        width: 300
        height: 400
        x: root.width - width - 8
        y: 48
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        radius: 8
        z: 1000

        SettingsView {
            anchors.fill: parent
            viewModel: settingsViewModel
            providerService: root.providerService
            onClosed: viewModel.showSettingsMenu = false
        }
    }


    Rectangle {
        id: overflowPopup
        visible: viewModel.showOverflowMenu
        width: 200
        height: 150
        x: root.width - width - 8
        y: 48
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        radius: 8
        z: 1000

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            DankButton {
                text: "New Chat"
                Layout.fillWidth: true
                enabled: viewModel.hasMessages && !viewModel.isStreaming
                onClicked: {
                    viewModel.clearHistory();
                    viewModel.closeMenus();
                }
            }

            DankButton {
                text: "Retry"
                Layout.fillWidth: true
                enabled: viewModel.hasMessages && !viewModel.isStreaming
                onClicked: {
                    viewModel.retry();
                    viewModel.closeMenus();
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.outline
            }

            DankButton {
                text: "Close"
                Layout.fillWidth: true
                onClicked: viewModel.closeMenus()
            }
        }
    }
}

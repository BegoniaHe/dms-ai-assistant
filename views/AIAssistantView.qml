import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import "components"
import "../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * AIAssistantView - Main chat interface
 * Uses ChatViewModel for UI state and commands
 * Refactored to use reusable components and Theme constants
 */
Item {
    id: root

    implicitWidth: ThemeConstants.Layout.mainWidth
    implicitHeight: ThemeConstants.Layout.mainHeight

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

    // Stream timer for elapsed time display
    Timer {
        id: streamTimer
        interval: ThemeConstants.Animations.streamUpdateInterval
        running: viewModel.isStreaming
        repeat: true
        onTriggered: nowMs = Date.now()
    }

    Column {
        anchors.fill: parent
        spacing: Theme.spacingM

        // Header with provider info and controls
        RowLayout {
            id: headerRow
            width: parent.width - Theme.spacingM * 2
            x: Theme.spacingM
            spacing: Theme.spacingS

            // Provider label
            Rectangle {
                radius: Theme.cornerRadius
                color: Theme.surfaceVariant
                height: Theme.fontSizeSmall * 1.6
                Layout.preferredWidth: providerLabel.implicitWidth + Theme.spacingM
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: providerLabel
                    anchors.centerIn: parent
                    text: (viewModel.getActiveProviderName() || "AI Assistant").toUpperCase()
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            // Online status indicator
            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: Theme.success
                Layout.alignment: Qt.AlignVCenter
            }

            // Streaming indicator
            Rectangle {
                visible: viewModel.isStreaming
                radius: Theme.cornerRadius
                color: Theme.surfaceVariant
                height: Theme.fontSizeSmall * 1.6
                Layout.preferredWidth: streamingText.implicitWidth + Theme.spacingM
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: streamingText
                    anchors.centerIn: parent
                    text: "Generating… %1s".arg(streamElapsedSeconds)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            // Transient hint
            Rectangle {
                visible: !viewModel.isStreaming && viewModel.transientHint.length > 0
                radius: Theme.cornerRadius
                color: Theme.surfaceVariant
                height: Theme.fontSizeSmall * 1.6
                Layout.preferredWidth: hintText.implicitWidth + Theme.spacingM
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: hintText
                    anchors.centerIn: parent
                    text: viewModel.transientHint
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            Item { Layout.fillWidth: true }

            // Settings button
            DankActionButton {
                iconName: "settings"
                tooltipText: viewModel.showSettingsMenu ? "Hide settings" : "Settings"
                onClicked: viewModel.toggleSettingsMenu()
            }

            // More options button
            DankActionButton {
                iconName: "more_vert"
                tooltipText: "More options"
                onClicked: viewModel.toggleOverflowMenu()
            }
        }

        // Message area
        Rectangle {
            width: parent.width - Theme.spacingM * 2
            height: parent.height - headerRow.height - composerRow.height - Theme.spacingM * 4
            x: Theme.spacingM
            radius: Theme.cornerRadius
            color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, root.panelTransparency)
            border.color: Theme.surfaceVariantAlpha
            border.width: 1

            MessageList {
                anchors.fill: parent
                messages: viewModel.messages
                onRetryRequested: (messageId) => viewModel.retry()
                onRegenerateRequested: (messageId) => viewModel.regenerate(messageId)
                onCopyRequested: (messageId) => viewModel.copyMessage(messageId)
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                width: parent.width * 0.86
                spacing: Theme.spacingM
                visible: !viewModel.hasMessages

                StyledText {
                    width: parent.width
                    text: "Start a conversation"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    width: parent.width
                    text: "Send a message to begin"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Message composer
        Rectangle {
            id: composerRow
            width: parent.width - Theme.spacingM * 2
            height: 116
            x: Theme.spacingM
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.surfaceContainerHigh, root.panelTransparency)
            border.color: composerField.activeFocus ? Theme.primary : Theme.outlineMedium
            border.width: composerField.activeFocus ? 2 : 1

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.shortDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.width {
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingXS

                DankTextField {
                    id: composerField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Type your message..."
                    text: viewModel.composerText
                    enabled: !viewModel.isStreaming
                    onTextChanged: viewModel.composerText = text

                    Keys.onReturnPressed: (event) => {
                        if (event.modifiers & Qt.ShiftModifier) {
                            text += "\n";
                        } else {
                            viewModel.sendMessage();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    DankButton {
                        text: viewModel.isStreaming ? "Cancel" : "Send"
                        Layout.fillWidth: true
                        enabled: composerField.text.trim().length > 0 || viewModel.isStreaming
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

    // Settings popup menu
    PopupMenu {
        isVisible: viewModel.showSettingsMenu
        width: ThemeConstants.Sizes.settingsMenuWidth
        height: ThemeConstants.Sizes.settingsMenuHeight
        x: root.width - width - Theme.spacingM
        y: Theme.spacingM * 2
        z: 1000

        content: Component {
            SettingsView {
                anchors.fill: parent
                viewModel: root.settingsViewModel
                providerService: root.providerService
                onClosed: root.viewModel.showSettingsMenu = false
            }
        }

        onClosed: root.viewModel.showSettingsMenu = false
    }

    // Overflow menu
    PopupMenu {
        isVisible: viewModel.showOverflowMenu
        width: ThemeConstants.Sizes.overflowMenuWidth
        height: ThemeConstants.Sizes.overflowMenuHeight
        x: root.width - width - Theme.spacingM
        y: Theme.spacingM * 2
        z: 1000

        content: Component {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingXS

                DankButton {
                    text: "New Chat"
                    Layout.fillWidth: true
                    enabled: root.viewModel.hasMessages && !root.viewModel.isStreaming
                    onClicked: {
                        root.viewModel.clearHistory();
                        root.viewModel.closeMenus();
                    }
                }

                DankButton {
                    text: "Retry"
                    Layout.fillWidth: true
                    enabled: root.viewModel.hasMessages && !root.viewModel.isStreaming
                    onClicked: {
                        root.viewModel.retry();
                        root.viewModel.closeMenus();
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
                    onClicked: root.viewModel.closeMenus()
                }
            }
        }

        onClosed: root.viewModel.showOverflowMenu = false
    }
}

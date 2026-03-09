import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import "../../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * MessageComposer - Message input and action component
 * Extracted from AIAssistantView for better organization
 */
Rectangle {
    id: root

    property alias text: textField.text
    property bool isStreaming: false
    property bool hasMessages: false

    signal sendClicked()
    signal cancelClicked()
    signal clearClicked()

    color: Theme.surface
    border.color: Theme.outline
    border.width: 1

    implicitHeight: ThemeConstants.Sizes.composerHeight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingXS

        // Text input field
        DankTextField {
            id: textField
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: "Type your message..."
            enabled: !root.isStreaming

            Keys.onReturnPressed: (event) => {
                if (event.modifiers & Qt.ShiftModifier) {
                    // Shift+Enter: new line
                    text += "\n";
                } else {
                    // Enter: send
                    root.sendClicked();
                }
            }

            Keys.onEscapePressed: {
                if (root.isStreaming) {
                    root.cancelClicked();
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            // Send/Cancel button
            DankButton {
                text: root.isStreaming ? "Cancel" : "Send"
                Layout.fillWidth: true
                enabled: textField.text.trim().length > 0 || root.isStreaming
                onClicked: {
                    if (root.isStreaming) {
                        root.cancelClicked();
                    } else {
                        root.sendClicked();
                    }
                }
            }

            // Clear button
            DankButton {
                text: "Clear"
                width: 60
                enabled: root.hasMessages && !root.isStreaming
                onClicked: root.clearClicked()
            }
        }
    }
}

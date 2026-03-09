import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets

/**
 * ProviderListItem - Provider list item component
 * Extracted from SettingsView for better organization and reusability
 */
Rectangle {
    id: root

    required property var providerData
    property bool isActive: false

    signal editClicked()
    signal deleteClicked()
    signal activateClicked()

    color: root.isActive ? Theme.primaryContainer : Theme.surface
    border.color: Theme.outline
    border.width: 1
    radius: 8

    implicitHeight: 60

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Provider info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            // Provider name
            StyledText {
                text: root.providerData.name
                font.weight: Font.Medium
                color: root.isActive ? Theme.primaryText : Theme.surfaceText
            }

            // Provider type and model
            StyledText {
                text: {
                    const typeMap = {
                        "openai-v1-compatible": "OpenAI v1",
                        "anthropic": "Anthropic",
                        "gemini": "Gemini"
                    };
                    const typeName = typeMap[root.providerData.type] || root.providerData.type;
                    return typeName + " • " + root.providerData.model;
                }
                font.pixelSize: Theme.fontSizeSmall
                opacity: 0.7
                color: root.isActive ? Theme.primaryText : Theme.surfaceText
            }
        }

        // Edit button
        DankButton {
            text: "Edit"
            width: 50
            height: 28
            onClicked: root.editClicked()
        }

        // Delete button
        DankButton {
            text: "Delete"
            width: 60
            height: 28
            enabled: !root.isActive
            onClicked: root.deleteClicked()
        }

        // Use button (only show if not active)
        DankButton {
            text: "Use"
            width: 50
            height: 28
            visible: !root.isActive
            onClicked: root.activateClicked()
        }
    }
}

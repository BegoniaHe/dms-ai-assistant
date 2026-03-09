import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets

/**
 * ChatHeader - Header component for chat interface
 * Displays provider name and action buttons
 */
Rectangle {
    id: root

    required property string providerName

    signal settingsClicked()
    signal menuClicked()

    color: Theme.surface
    border.color: Theme.outline
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Provider name
        StyledText {
            text: root.providerName
            font.weight: Font.Medium
            font.pixelSize: Theme.fontSizeMedium
            Layout.fillWidth: true
        }

        // Settings button
        DankActionButton {
            iconName: "settings"
            buttonSize: 32
            iconSize: 18
            backgroundColor: "transparent"
            tooltipText: "Settings"
            onClicked: root.settingsClicked()
        }

        // More options button
        DankActionButton {
            iconName: "more_vert"
            buttonSize: 32
            iconSize: 18
            backgroundColor: "transparent"
            tooltipText: "More options"
            onClicked: root.menuClicked()
        }
    }
}

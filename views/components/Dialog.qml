import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import "../../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * Dialog - Reusable modal dialog component
 * Replaces hardcoded dialog rectangles with a unified, animated component
 */
Rectangle {
    id: root

    property bool isVisible: false
    required property string title
    required property Component content

    property real dialogWidth: ThemeConstants.Sizes.dialogWidth
    property real dialogHeight: ThemeConstants.Sizes.dialogHeight

    signal closed()

    // Position and size
    anchors.fill: parent
    color: "transparent"
    border.width: 0
    z: 999

    // Semi-transparent background overlay
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Theme.withAlpha(Theme.background, 0.5)
        opacity: root.isVisible ? 1 : 0
        visible: opacity > 0
        z: 999

        MouseArea {
            anchors.fill: parent
            onClicked: root.closed()
        }

        Behavior on opacity {
            NumberAnimation {
                duration: ThemeConstants.Animations.hintFadeDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    // Dialog container
    Rectangle {
        id: dialogBox
        width: root.dialogWidth
        height: root.dialogHeight
        anchors.centerIn: parent
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        radius: 12
        z: 1000

        opacity: root.isVisible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: ThemeConstants.Animations.hintFadeDuration
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            // Title
            StyledText {
                text: root.title
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                Layout.fillWidth: true
            }

            // Content area
            Loader {
                sourceComponent: root.content
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}

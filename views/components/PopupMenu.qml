import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import "../../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * PopupMenu - Reusable popup menu component
 * Replaces hardcoded popup rectangles with animated, positioned menus
 */
Rectangle {
    id: root

    property bool isVisible: false
    required property Component content

    signal closed()

    color: Theme.surface
    border.color: Theme.outline
    border.width: 1
    radius: 12
    z: 1000

    opacity: root.isVisible ? 1 : 0
    visible: opacity > 0

    // Fade and slide animation
    Behavior on opacity {
        NumberAnimation {
            duration: ThemeConstants.Animations.menuSlideInDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: ThemeConstants.Animations.menuSlideInDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: ThemeConstants.Animations.menuSlideInDuration
            easing.type: Easing.OutCubic
        }
    }

    // Close on click outside
    MouseArea {
        anchors.fill: root.parent
        z: 999
        onClicked: root.closed()
    }

    // Content area
    Loader {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        sourceComponent: root.content
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import "../../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * HintBar - Reusable hint/notification bar component
 * Replaces hardcoded hint rectangle with animated, typed notifications
 */
Rectangle {
    id: root

    property string message: ""
    property string type: "info"  // info, warning, error
    property bool autoHide: true
    property int duration: ThemeConstants.Animations.hintDuration

    implicitHeight: message.length > 0 ? ThemeConstants.Sizes.hintBarHeight : 0
    visible: message.length > 0
    clip: true

    // Color based on type
    color: {
        switch (type) {
            case "warning":
                return Theme.withAlpha(Theme.warning, 0.1);
            case "error":
                return Theme.withAlpha(Theme.error, 0.1);
            case "info":
            default:
                return Theme.withAlpha(Theme.primary, 0.1);
        }
    }

    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: root.duration
        running: root.autoHide && root.message.length > 0
        onTriggered: root.message = ""
    }

    // Fade animation
    Behavior on opacity {
        NumberAnimation {
            duration: ThemeConstants.Animations.hintFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    // Height animation
    Behavior on implicitHeight {
        NumberAnimation {
            duration: ThemeConstants.Animations.hintFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Icon
        DankIcon {
            name: {
                switch (root.type) {
                    case "warning":
                        return "warning";
                    case "error":
                        return "error";
                    case "info":
                    default:
                        return "info";
                }
            }
            size: 18
            color: {
                switch (root.type) {
                    case "warning":
                        return Theme.warning;
                    case "error":
                        return Theme.error;
                    case "info":
                    default:
                        return Theme.primary;
                }
            }
        }

        // Message text
        StyledText {
            text: root.message
            color: {
                switch (root.type) {
                    case "warning":
                        return Theme.warning;
                    case "error":
                        return Theme.error;
                    case "info":
                    default:
                        return Theme.primary;
                }
            }
            Layout.fillWidth: true
            font.pixelSize: Theme.fontSizeMedium
        }

        // Close button
        DankActionButton {
            iconName: "close"
            buttonSize: 24
            iconSize: 14
            backgroundColor: "transparent"
            onClicked: root.message = ""
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import "../markdown2html.mjs" as Markdown2Html
import qs.Widgets
import "../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * MessageBubble - Individual message display component
 * Refactored to use Theme constants and improved layout
 */
Item {
    id: root

    property string role: "assistant"
    property string messageId: ""
    property string text: ""
    property string status: "ok"  // ok|streaming|error|cancelled
    property bool useMonospace: false

    signal retryRequested(string messageId)
    signal regenerateRequested(string messageId)
    signal copyRequested(string messageId)

    readonly property bool isUser: role === "user"
    readonly property real bubbleMaxWidth: isUser ? Math.max(240, Math.floor(width * 0.82)) : width
    readonly property color userBubbleFill: Theme.withAlpha(Theme.primary, 0.1)
    readonly property color userBubbleBorder: Theme.withAlpha(Theme.primary, 0.3)
    readonly property color assistantBubbleFill: Theme.surfaceContainer
    readonly property color assistantBubbleBorder: Theme.outline

    readonly property var themeColors: ({
        "codeBg": Theme.surfaceContainerHigh,
        "blockquoteBg": Theme.withAlpha(Theme.surfaceContainerHighest, 0.5),
        "blockquoteBorder": Theme.outlineVariant,
        "inlineCodeBg": Theme.withAlpha(Theme.onSurface, 0.1)
    })

    readonly property bool useMarkdownRendering: !isUser && status !== "streaming"
    readonly property string renderedHtml: Markdown2Html.markdownToHtml(root.text, themeColors)

    width: parent ? parent.width : implicitWidth
    implicitHeight: bubble.implicitHeight

    Rectangle {
        id: bubble
        width: Math.min(root.bubbleMaxWidth, root.width)
        x: root.isUser ? (root.width - width) : 0
        radius: ThemeConstants.Sizes.bubbleRadius
        color: root.isUser ? root.userBubbleFill : root.assistantBubbleFill
        border.color: root.status === "error" ? Theme.error : (root.isUser ? root.userBubbleBorder : root.assistantBubbleBorder)
        border.width: 1

        implicitHeight: contentColumn.implicitHeight + (ThemeConstants.Sizes.bubblePadding * 2)
        height: implicitHeight

        Behavior on x {
            NumberAnimation {
                duration: ThemeConstants.Animations.bubbleAnimationDuration
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: contentColumn
            x: ThemeConstants.Sizes.bubblePadding
            y: ThemeConstants.Sizes.bubblePadding
            width: parent.width - (ThemeConstants.Sizes.bubblePadding * 2)
            spacing: Theme.spacingM

            // Header row with role and actions
            RowLayout {
                id: headerRow
                width: parent.width
                spacing: Theme.spacingXS
                layoutDirection: root.isUser ? Qt.RightToLeft : Qt.LeftToRight

                // Role badge
                Rectangle {
                    radius: Theme.cornerRadius / 2
                    color: root.isUser ? Theme.withAlpha(Theme.primary, 0.14) : Theme.surfaceVariant
                    implicitWidth: headerText.implicitWidth + Theme.spacingS
                    implicitHeight: Theme.fontSizeSmall + Theme.spacingXS

                    StyledText {
                        id: headerText
                        anchors.centerIn: parent
                        text: root.isUser ? "You" : "Assistant"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: root.isUser ? Theme.primary : Theme.surfaceVariantText
                    }
                }

                // Avatar icon
                Rectangle {
                    Layout.preferredWidth: ThemeConstants.Sizes.bubbleAvatarSize
                    Layout.preferredHeight: ThemeConstants.Sizes.bubbleAvatarSize
                    radius: ThemeConstants.Sizes.bubbleAvatarSize / 2
                    color: root.isUser ? Theme.withAlpha(Theme.primary, 0.20) : Theme.surfaceVariant
                    border.width: 1
                    border.color: root.isUser ? Theme.withAlpha(Theme.primary, 0.35) : Theme.outlineVariant

                    DankIcon {
                        anchors.centerIn: parent
                        name: root.isUser ? "person" : "smart_toy"
                        size: ThemeConstants.Sizes.bubbleActionIconSize
                        color: root.isUser ? Theme.primary : Theme.surfaceVariantText
                    }
                }

                Item { Layout.fillWidth: true }

                // Regenerate button
                DankActionButton {
                    visible: !root.isUser && root.status === "ok"
                    iconName: "refresh"
                    buttonSize: ThemeConstants.Sizes.bubbleActionButtonSize
                    iconSize: ThemeConstants.Sizes.bubbleActionIconSize
                    backgroundColor: "transparent"
                    iconColor: Theme.surfaceVariantText
                    tooltipText: "Regenerate"
                    onClicked: root.regenerateRequested(root.messageId)
                }

                // Copy button
                DankActionButton {
                    visible: !root.isUser && root.status === "ok"
                    iconName: "content_copy"
                    buttonSize: ThemeConstants.Sizes.bubbleActionButtonSize
                    iconSize: ThemeConstants.Sizes.bubbleActionIconSize
                    backgroundColor: "transparent"
                    iconColor: Theme.surfaceVariantText
                    tooltipText: "Copy"
                    enabled: (root.text || "").trim().length > 0
                    onClicked: {
                        Quickshell.execDetached(["wl-copy", root.text]);
                        root.copyRequested(root.messageId);
                    }
                }
            }

            Item {
                width: 1
                Layout.topMargin: Theme.spacingXS
            }

            // Error indicator
            StyledText {
                visible: root.status === "error"
                text: "Error"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.error
                width: parent.width
            }

            // Message text
            TextArea {
                id: messageText
                text: root.useMarkdownRendering ? root.renderedHtml : root.text
                textFormat: root.useMarkdownRendering ? Text.RichText : Text.PlainText
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                font.family: root.useMonospace ? "monospace" : Theme.fontFamily
                color: root.status === "error" ? Theme.error : Theme.surfaceText
                width: parent.width

                readOnly: true
                selectByMouse: true
                selectionColor: Theme.primary
                selectedTextColor: Theme.onPrimary
                background: null
                leftPadding: Theme.spacingXS
                rightPadding: Theme.spacingXS

                hoverEnabled: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                }

                onLinkActivated: link => {
                    if (link.startsWith("copy://")) {
                        const b64 = link.substring(7);
                        try {
                            const code = Qt.atob(b64);
                            Quickshell.execDetached(["wl-copy", code]);
                            root.copyRequested(root.messageId);
                        } catch (e) {
                            console.error("[MessageBubble] Failed to copy code:", e);
                        }
                    } else {
                        Qt.openUrlExternally(link);
                    }
                }
            }

            // Streaming indicator
            Rectangle {
                visible: root.status === "streaming"
                radius: Theme.cornerRadius / 2
                color: Theme.surfaceVariant
                implicitHeight: Theme.fontSizeSmall + Theme.spacingXS
                implicitWidth: streamingText.implicitWidth + Theme.spacingS
                x: root.isUser ? (parent.width - width) : 0

                StyledText {
                    id: streamingText
                    anchors.centerIn: parent
                    text: "Streaming…"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}

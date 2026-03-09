import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import "../markdown2html.mjs" as Markdown2Html
import qs.Widgets

/**
 * MessageBubble - Individual message display component
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
    readonly property color userBubbleFill: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
    readonly property color userBubbleBorder: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
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
        radius: 8
        color: root.isUser ? root.userBubbleFill : root.assistantBubbleFill
        border.color: root.status === "error" ? Theme.error : (root.isUser ? root.userBubbleBorder : root.assistantBubbleBorder)
        border.width: 1

        implicitHeight: contentColumn.implicitHeight + 16
        height: implicitHeight

        Behavior on x {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: contentColumn
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 8

            // Header row with role and actions
            RowLayout {
                id: headerRow
                width: parent.width
                spacing: 4

                Item {
                    Layout.fillWidth: root.isUser
                }

                Rectangle {
                    radius: 4
                    color: root.isUser ? Theme.withAlpha(Theme.primary, 0.14) : Theme.surfaceVariant
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: headerText.implicitWidth + 8

                    StyledText {
                        id: headerText
                        anchors.centerIn: parent
                        text: root.isUser ? "You" : "Assistant"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.isUser ? Theme.primary : Theme.surfaceVariantText
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    radius: 9
                    color: root.isUser ? Theme.withAlpha(Theme.primary, 0.20) : Theme.surfaceVariant
                    border.width: 1
                    border.color: root.isUser ? Theme.withAlpha(Theme.primary, 0.35) : Theme.surfaceVariantAlpha

                    DankIcon {
                        anchors.centerIn: parent
                        name: root.isUser ? "person" : "smart_toy"
                        size: 14
                        color: root.isUser ? Theme.primary : Theme.surfaceVariantText
                    }
                }

                Item {
                    Layout.fillWidth: !root.isUser
                }

                // Regenerate button
                DankActionButton {
                    visible: !root.isUser && root.status === "ok"
                    iconName: "refresh"
                    buttonSize: 24
                    iconSize: 14
                    backgroundColor: "transparent"
                    iconColor: Theme.surfaceVariantText
                    tooltipText: "Regenerate"
                    onClicked: root.regenerateRequested(root.messageId)
                }

                // Copy button
                DankActionButton {
                    visible: !root.isUser && root.status === "ok"
                    iconName: "content_copy"
                    buttonSize: 24
                    iconSize: 14
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
                height: 4
            }

            // Error indicator
            StyledText {
                visible: root.status === "error"
                text: "Error"
                font.pixelSize: 11
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
                font.pixelSize: 13
                font.family: root.useMonospace ? "monospace" : Theme.fontFamily
                color: root.status === "error" ? Theme.error : Theme.surfaceText
                width: parent.width

                readOnly: true
                selectByMouse: true
                selectionColor: Theme.primary
                selectedTextColor: Theme.onPrimary
                background: null
                leftPadding: 4
                rightPadding: 4

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
                radius: 4
                color: Theme.surfaceVariant
                height: 20
                width: streamingText.implicitWidth + 8
                x: root.isUser ? (parent.width - width) : 0

                StyledText {
                    id: streamingText
                    anchors.centerIn: parent
                    text: "Streaming…"
                    font.pixelSize: 11
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}

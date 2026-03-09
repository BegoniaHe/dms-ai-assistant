import QtQuick
import QtQuick.Controls
import qs.Common
import "../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * MessageList - Displays chat messages
 * Refactored to use Theme constants and improved scroll behavior
 */
Item {
    id: root
    clip: true

    property var messages: []
    property bool stickToBottom: true
    property bool useMonospace: false

    signal retryRequested(string messageId)
    signal regenerateRequested(string messageId)
    signal copyRequested(string messageId)

    Component.onCompleted: console.log("[MessageList] ready")

    // Scroll to bottom when messages change
    onMessagesChanged: {
        if (stickToBottom) {
            Qt.callLater(() => listView.positionViewAtEnd());
        }
    }

    // Give the markdown layout time to settle before scrolling
    Timer {
        id: scrollSettleTimer
        interval: 32
        repeat: false
        onTriggered: listView.positionViewAtEnd()
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM
        clip: true
        ScrollBar.vertical: ScrollBar {}

        model: root.messages

        onContentYChanged: {
            const maxY = Math.max(0, listView.contentHeight - listView.height);
            root.stickToBottom = listView.contentY >= maxY - Theme.spacingM;
        }

        onContentHeightChanged: {
            if (root.stickToBottom) {
                Qt.callLater(() => listView.positionViewAtEnd());
            }
        }

        delegate: Item {
            id: wrapper
            width: listView.width

            readonly property string previousRole: (index > 0 && root.messages) ? (root.messages[index - 1].role || "") : ""
            readonly property bool roleChanged: previousRole.length > 0 && previousRole !== (modelData.role || "")
            readonly property int topGap: roleChanged ? Theme.spacingM : 0

            implicitHeight: bubble.implicitHeight + topGap

            MessageBubble {
                id: bubble
                width: listView.width - Theme.spacingM * 2
                x: Theme.spacingM
                y: wrapper.topGap

                messageId: modelData.id
                role: modelData.role
                text: modelData.content
                status: modelData.status
                useMonospace: root.useMonospace

                onRetryRequested: (id) => root.retryRequested(id)
                onRegenerateRequested: (id) => root.regenerateRequested(id)
                onCopyRequested: (id) => root.copyRequested(id)
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import qs.Common

/**
 * MessageList - Displays chat messages
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

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        clip: true
        ScrollBar.vertical: ScrollBar {}

        model: root.messages

        onContentYChanged: {
            const maxY = Math.max(0, listView.contentHeight - listView.height);
            root.stickToBottom = listView.contentY >= maxY - 20;
        }

        onContentHeightChanged: {
            if (root.stickToBottom) {
                Qt.callLater(() => listView.positionViewAtEnd());
            }
        }

        delegate: Item {
            id: wrapper
            required property int index
            required property var modelData

            width: listView.width - 16
            implicitHeight: bubble.implicitHeight + 8

            MessageBubble {
                id: bubble
                width: wrapper.width
                messageId: wrapper.modelData.id
                role: wrapper.modelData.role
                text: wrapper.modelData.content
                status: wrapper.modelData.status
                useMonospace: root.useMonospace

                onRetryRequested: (id) => root.retryRequested(id)
                onRegenerateRequested: (id) => root.regenerateRequested(id)
                onCopyRequested: (id) => root.copyRequested(id)
            }
        }
    }
}

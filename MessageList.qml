import QtQuick
import QtQuick.Controls
import qs.Common

Item {
    id: root
    clip: true
    property var messages: null // expects a ListModel
    property var aiService: null
    property bool stickToBottom: true
    property bool useMonospace: false
    signal copySuccess

    Component.onCompleted: console.log("[MessageList] ready")

    // Scroll to bottom when a new message is appended.
    Connections {
        target: root.messages
        function onCountChanged() {
            if (root.stickToBottom) {
                Qt.callLater(() => listView.positionViewAtEnd());
            }
        }
    }

    // Scroll to bottom when streaming ends so the fully-rendered markdown
    // (which can be significantly taller than the streaming plain text) is visible.
    Connections {
        target: root.aiService
        function onIsStreamingChanged() {
            if (root.aiService && !root.aiService.isStreaming) {
                scrollSettleTimer.restart();
            }
        }
    }

    // Give the markdown layout two frames to settle before scrolling.
    Timer {
        id: scrollSettleTimer
        interval: 32
        repeat: false
        onTriggered: listView.positionViewAtEnd()
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        model: root.messages
        spacing: Theme.spacingM
        clip: true
        ScrollBar.vertical: ScrollBar {}

        onContentYChanged: {
            // Use a small tolerance to avoid stickToBottom flipping to false
            // while positionViewAtEnd() is mid-flight during a height update.
            const maxY = Math.max(0, listView.contentHeight - listView.height);
            root.stickToBottom = listView.contentY >= maxY - 20;
        }

        onContentHeightChanged: {
            if (root.stickToBottom) {
                Qt.callLater(() => listView.positionViewAtEnd());
            }
        }

        onModelChanged: {
            Qt.callLater(() => {
                root.stickToBottom = true;
                listView.positionViewAtEnd();
            });
        }

        delegate: Item {
            id: wrapper
            required property int index
            required property var model
            // Outer-scope aliases (delegate cannot qualify outer IDs without pragma)
            property real listWidth: listView.width // qmllint disable unqualified
            property var outerMessages: root.messages // qmllint disable unqualified
            property bool outerUseMonospace: root.useMonospace // qmllint disable unqualified
            property var outerAiService: root.aiService // qmllint disable unqualified

            width: wrapper.listWidth

            readonly property string previousRole: (wrapper.index > 0 && wrapper.outerMessages) ? (wrapper.outerMessages.get(wrapper.index - 1).role || "") : ""
            readonly property bool roleChanged: previousRole.length > 0 && previousRole !== (wrapper.model.role || "")
            readonly property int topGap: roleChanged ? Theme.spacingM : 0

            implicitHeight: bubble.implicitHeight + topGap

            MessageBubble {
                id: bubble
                width: wrapper.listWidth
                y: wrapper.topGap
                messageId: wrapper.model.id
                role: wrapper.model.role
                text: wrapper.model.content
                status: wrapper.model.status
                useMonospace: wrapper.outerUseMonospace

                onCopySuccess: root.copySuccess() // qmllint disable unqualified

                Component.onCompleted: {
                    console.log("[MessageList] add", role, text ? text.slice(0, 40) : "");
                }

                onRegenerateRequested: messageId => {
                    if (!wrapper.outerAiService || !wrapper.outerAiService.regenerateFromMessageId)
                        return;
                    console.log("[MessageList] regenerate requested for message id", messageId);
                    wrapper.outerAiService.regenerateFromMessageId(messageId);
                }
            }
        }
    }
}

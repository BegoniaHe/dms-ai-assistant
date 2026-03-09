import QtQuick
import "../data/repositories"

/**
 * ChatService - Core chat logic and message orchestration
 * Handles message sending, streaming, retry, and regeneration
 */
Item {
    id: root

    required property var providerService
    required property var sessionService
    required property var streamingService

    // Messages model
    property var messagesModel: []
    property int messageCount: 0
    property bool isStreaming: false

    // Current streaming state
    property string currentStreamingMessageId: ""
    property string currentStreamingContent: ""

    // Signals
    signal messageSent(string messageId)
    signal messageReceived(string messageId, string content)
    signal streamStarted()
    signal streamFinished()
    signal streamError(string message)

    Component.onCompleted: {
        // Connect to session changes
        sessionService.messagesChanged.connect(onSessionMessagesChanged);
        streamingService.chunkReceived.connect(onChunkReceived);
        streamingService.streamFinished.connect(onStreamFinished);
        streamingService.streamError.connect(onStreamError);
    }

    /**
     * Generate unique message ID
     */
    function generateMessageId() {
        return "msg-" + Date.now() + "-" + Math.random().toString(36).substr(2, 9);
    }

    /**
     * Send a new message
     */
    function sendMessage(content) {
        if (!content || content.trim().length === 0) {
            console.warn("[ChatService] Empty message");
            return;
        }

        if (isStreaming) {
            console.warn("[ChatService] Already streaming");
            return;
        }

        const activeInstance = providerService.getActiveInstance();
        if (!activeInstance) {
            console.error("[ChatService] No active provider instance");
            streamError("No active provider instance");
            return;
        }

        // Add user message
        const userMessageId = generateMessageId();
        const userMessage = {
            id: userMessageId,
            role: "user",
            content: content.trim(),
            timestamp: Date.now(),
            status: "ok"
        };

        sessionService.addMessage(userMessage);
        messageSent(userMessageId);
        console.log("[ChatService] Sent user message:", userMessageId);

        // Start streaming assistant response
        startStreaming(activeInstance.id);
    }

    /**
     * Start streaming assistant response
     */
    function startStreaming(instanceId) {
        const instance = providerService.getInstance(instanceId);
        if (!instance) {
            console.error("[ChatService] Instance not found:", instanceId);
            return;
        }

        // Create assistant message placeholder
        currentStreamingMessageId = generateMessageId();
        currentStreamingContent = "";

        const assistantMessage = {
            id: currentStreamingMessageId,
            role: "assistant",
            content: "",
            timestamp: Date.now(),
            status: "streaming"
        };

        sessionService.addMessage(assistantMessage);

        // Build context messages
        const contextMessages = sessionService.getContextMessages(20);
        const messages = contextMessages.map(m => ({
            role: m.role,
            content: m.content
        }));

        isStreaming = true;
        streamStarted();

        console.log("[ChatService] Starting stream with", messages.length, "context messages");

        streamingService.startStream(
            instanceId,
            messages,
            function(chunk) {
                // onChunk - handled by onChunkReceived
            },
            function(status) {
                // onDone - handled by onStreamFinished
            },
            function(error) {
                // onError - handled by onStreamError
            }
        );
    }

    /**
     * Handle incoming chunk
     */
    function onChunkReceived(content) {
        currentStreamingContent += content;
        sessionService.updateMessage(currentStreamingMessageId, {
            content: currentStreamingContent
        });
        messageReceived(currentStreamingMessageId, currentStreamingContent);
    }

    /**
     * Handle stream finished
     */
    function onStreamFinished() {
        isStreaming = false;

        // Mark message as complete
        sessionService.updateMessage(currentStreamingMessageId, {
            status: "ok"
        });

        streamFinished();
        console.log("[ChatService] Stream finished, received", currentStreamingContent.length, "chars");
    }

    /**
     * Handle stream error
     */
    function onStreamError(error) {
        isStreaming = false;

        // Mark message as error
        sessionService.updateMessage(currentStreamingMessageId, {
            status: "error",
            content: "Error: " + error
        });

        streamError(error);
        console.error("[ChatService] Stream error:", error);
    }

    /**
     * Retry last message
     */
    function retryLast() {
        if (isStreaming) {
            console.warn("[ChatService] Already streaming");
            return;
        }

        // Find last user message
        let lastUserIndex = -1;
        for (let i = sessionService.currentMessages.length - 1; i >= 0; i--) {
            if (sessionService.currentMessages[i].role === "user") {
                lastUserIndex = i;
                break;
            }
        }

        if (lastUserIndex === -1) {
            console.warn("[ChatService] No user message to retry");
            return;
        }

        // Remove all messages after last user message
        const messagesToKeep = sessionService.currentMessages.slice(0, lastUserIndex + 1);
        sessionService.currentMessages = messagesToKeep;
        sessionService.saveMessages();
        sessionService.messagesChanged();

        // Start streaming
        const activeInstance = providerService.getActiveInstance();
        if (activeInstance) {
            startStreaming(activeInstance.id);
        }

        console.log("[ChatService] Retrying from message index:", lastUserIndex);
    }

    /**
     * Regenerate from a specific message
     */
    function regenerateFromMessageId(messageId) {
        if (isStreaming) {
            console.warn("[ChatService] Already streaming");
            return;
        }

        // Find message index
        let messageIndex = -1;
        for (let i = 0; i < sessionService.currentMessages.length; i++) {
            if (sessionService.currentMessages[i].id === messageId) {
                messageIndex = i;
                break;
            }
        }

        if (messageIndex === -1) {
            console.warn("[ChatService] Message not found:", messageId);
            return;
        }

        // Keep messages up to and including this message
        const messagesToKeep = sessionService.currentMessages.slice(0, messageIndex + 1);
        sessionService.currentMessages = messagesToKeep;
        sessionService.saveMessages();
        sessionService.messagesChanged();

        // Start streaming
        const activeInstance = providerService.getActiveInstance();
        if (activeInstance) {
            startStreaming(activeInstance.id);
        }

        console.log("[ChatService] Regenerating from message:", messageId);
    }

    /**
     * Cancel current streaming
     */
    function cancel() {
        if (!isStreaming) {
            console.warn("[ChatService] Not streaming");
            return;
        }

        streamingService.cancel();
        isStreaming = false;

        // Mark message as cancelled
        if (currentStreamingMessageId) {
            sessionService.updateMessage(currentStreamingMessageId, {
                status: "cancelled"
            });
        }

        console.log("[ChatService] Cancelled streaming");
    }

    /**
     * Clear all messages
     */
    function clearHistory(confirm) {
        if (!confirm) {
            console.warn("[ChatService] Confirm required to clear history");
            return;
        }

        sessionService.clearMessages();
        messagesModel = [];
        messageCount = 0;
        console.log("[ChatService] Cleared history");
    }

    /**
     * Handle session messages changed
     */
    function onSessionMessagesChanged() {
        messagesModel = sessionService.currentMessages;
        messageCount = messagesModel.length;
    }

    /**
     * Get all messages
     */
    function getMessages() {
        return messagesModel;
    }

    /**
     * Get message by ID
     */
    function getMessage(messageId) {
        return messagesModel.find(m => m.id === messageId) || null;
    }
}

import QtQuick
import "../data/repositories"

/**
 * SessionService - Manages chat sessions and history per provider instance
 * Handles loading, saving, and switching between instance sessions
 */
Item {
    id: root

    required property var sessionRepository

    // Current messages for active instance
    property var currentMessages: []
    property string activeInstanceId: ""

    // Signals
    signal messagesChanged()
    signal instanceSwitched(string instanceId)

    /**
     * Load messages for a specific instance
     */
    function loadMessages(instanceId) {
        const messages = sessionRepository.loadMessages(instanceId);
        activeInstanceId = instanceId;
        currentMessages = messages;
        messagesChanged();
        console.log("[SessionService] Loaded", messages.length, "messages for instance:", instanceId);
        return messages;
    }

    /**
     * Save current messages
     */
    function saveMessages() {
        if (!activeInstanceId) {
            console.warn("[SessionService] No active instance");
            return;
        }
        sessionRepository.saveMessages(activeInstanceId, currentMessages);
        console.log("[SessionService] Saved", currentMessages.length, "messages");
    }

    /**
     * Add a message to current session
     */
    function addMessage(message) {
        if (!activeInstanceId) {
            console.warn("[SessionService] No active instance");
            return;
        }

        currentMessages = currentMessages.concat([message]);
        saveMessages();
        messagesChanged();
    }

    /**
     * Update a message in current session
     */
    function updateMessage(messageId, updates) {
        const index = currentMessages.findIndex(m => m.id === messageId);
        if (index === -1) {
            console.warn("[SessionService] Message not found:", messageId);
            return;
        }

        const updated = Object.assign({}, currentMessages[index], updates);
        const next = currentMessages.slice();
        next[index] = updated;
        currentMessages = next;
        saveMessages();
        messagesChanged();
    }

    /**
     * Remove a message from current session
     */
    function removeMessage(messageId) {
        const index = currentMessages.findIndex(m => m.id === messageId);
        if (index === -1) {
            console.warn("[SessionService] Message not found:", messageId);
            return;
        }

        currentMessages = currentMessages.filter(m => m.id !== messageId);
        saveMessages();
        messagesChanged();
    }

    /**
     * Clear all messages in current session
     */
    function clearMessages() {
        if (!activeInstanceId) {
            console.warn("[SessionService] No active instance");
            return;
        }

        currentMessages = [];
        sessionRepository.clearMessages(activeInstanceId);
        messagesChanged();
        console.log("[SessionService] Cleared messages");
    }

    /**
     * Switch to a different instance's session
     */
    function switchToInstance(instanceId) {
        loadMessages(instanceId);
        instanceSwitched(instanceId);
        console.log("[SessionService] Switched to instance:", instanceId);
    }

    /**
     * Delete all messages for an instance
     */
    function deleteInstanceMessages(instanceId) {
        sessionRepository.deleteMessages(instanceId);
        if (activeInstanceId === instanceId) {
            currentMessages = [];
            messagesChanged();
        }
        console.log("[SessionService] Deleted messages for instance:", instanceId);
    }

    /**
     * Get message count
     */
    function getMessageCount() {
        return currentMessages.length;
    }

    /**
     * Get last message
     */
    function getLastMessage() {
        return currentMessages.length > 0 ? currentMessages[currentMessages.length - 1] : null;
    }

    /**
     * Get messages for building context (last N messages)
     */
    function getContextMessages(limit) {
        const n = limit || 20;
        return currentMessages.slice(Math.max(0, currentMessages.length - n));
    }
}

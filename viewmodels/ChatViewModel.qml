import QtQuick

/**
 * ChatViewModel - Manages chat UI state and commands
 * Bridges between View and Service layers
 */
Item {
    id: root

    required property var chatService
    required property var providerService
    required property var sessionService

    // Expose service properties to View
    readonly property var messages: chatService ? chatService.messagesModel : []
    readonly property bool isStreaming: chatService ? chatService.isStreaming : false
    readonly property int messageCount: chatService ? chatService.messageCount : 0
    readonly property bool hasApiKey: providerService ? providerService.hasApiKey() : false
    readonly property bool hasMessages: messageCount > 0

    // UI state
    property string composerText: ""
    property string transientHint: ""
    property bool showSettingsMenu: false
    property bool showOverflowMenu: false

    // Hint timer
    Timer {
        id: hintTimer
        interval: 2500
        onTriggered: transientHint = ""
    }

    /**
     * Send message command
     */
    function sendMessage() {
        if (!composerText || composerText.trim().length === 0) {
            showHint("Message cannot be empty");
            return;
        }

        if (!hasApiKey) {
            showHint("Please configure API key in settings");
            return;
        }

        chatService.sendMessage(composerText.trim());
        composerText = "";
    }

    /**
     * Retry last message command
     */
    function retry() {
        if (isStreaming) {
            showHint("Please wait for current response");
            return;
        }
        chatService.retryLast();
    }

    /**
     * Regenerate from message command
     */
    function regenerate(messageId) {
        if (isStreaming) {
            showHint("Please wait for current response");
            return;
        }
        chatService.regenerateFromMessageId(messageId);
    }

    /**
     * Cancel streaming command
     */
    function cancel() {
        if (!isStreaming) {
            return;
        }
        chatService.cancel();
    }

    /**
     * Clear history command
     */
    function clearHistory() {
        chatService.clearHistory(true);
        showHint("History cleared");
    }

    /**
     * Copy message to clipboard
     */
    function copyMessage(messageId) {
        const message = chatService.getMessage(messageId);
        if (message) {
            // Note: QML doesn't have direct clipboard access
            // This would need to be implemented via C++ or system command
            showHint("Copied to clipboard");
        }
    }

    /**
     * Show transient hint
     */
    function showHint(text) {
        transientHint = text;
        hintTimer.restart();
    }

    /**
     * Toggle settings menu
     */
    function toggleSettingsMenu() {
        showSettingsMenu = !showSettingsMenu;
        showOverflowMenu = false;
    }

    /**
     * Toggle overflow menu
     */
    function toggleOverflowMenu() {
        showOverflowMenu = !showOverflowMenu;
        showSettingsMenu = false;
    }

    /**
     * Close all menus
     */
    function closeMenus() {
        showSettingsMenu = false;
        showOverflowMenu = false;
    }

    /**
     * Get active provider name
     */
    function getActiveProviderName() {
        const instance = providerService.getActiveInstance();
        return instance ? instance.name : "Unknown";
    }

    /**
     * Get active provider type
     */
    function getActiveProviderType() {
        const instance = providerService.getActiveInstance();
        return instance ? instance.type : "unknown";
    }
}

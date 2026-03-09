import QtQuick
import "../data/api/ProviderAdapters.js" as ProviderAdapters

/**
 * StreamingService - Manages XHR streaming lifecycle and chunk processing
 * Handles request initiation, chunk parsing, and error handling
 */
Item {
    id: root

    required property var providerService

    property var currentXhr: null
    property bool isStreaming: false
    property string currentError: ""

    // Signals
    signal chunkReceived(string content)
    signal streamFinished()
    signal streamError(string message)
    signal streamCancelled()

    // Timer for request timeout (Qt QML XMLHttpRequest doesn't support xhr.timeout)
    Timer {
        id: timeoutTimer
        repeat: false
        onTriggered: {
            if (currentXhr) {
                currentXhr.abort();
                handleError("Request timeout", null);
            }
        }
    }

    /**
     * Start a streaming request
     */
    function startStream(instanceId, messages, onChunk, onDone, onError) {
        if (isStreaming) {
            console.warn("[StreamingService] Already streaming");
            return;
        }

        const instance = providerService.getInstance(instanceId);
        if (!instance) {
            const msg = "Instance not found: " + instanceId;
            console.error("[StreamingService]", msg);
            onError(msg);
            return;
        }

        const apiKey = providerService.resolveApiKey(instanceId);
        if (!apiKey) {
            const msg = "No API key configured for instance: " + instanceId;
            console.error("[StreamingService]", msg);
            onError(msg);
            return;
        }

        isStreaming = true;
        currentError = "";

        const payload = {
            baseUrl: instance.baseUrl,
            model: instance.model,
            messages: messages,
            max_tokens: instance.maxTokens,
            temperature: instance.temperature,
            timeout: instance.timeout
        };

        console.log("[StreamingService] Starting stream for instance:", instanceId, "type:", instance.type);

        // Start timeout timer
        timeoutTimer.interval = (instance.timeout || 30) * 1000;
        timeoutTimer.start();

        currentXhr = ProviderAdapters.sendStreamRequest(
            instance.type,
            payload,
            apiKey,
            function(chunk) {
                handleChunk(instance.type, chunk, onChunk);
            },
            function(status) {
                timeoutTimer.stop();
                handleDone(status, onDone);
            },
            function(error) {
                timeoutTimer.stop();
                handleError(error, onError);
            }
        );
    }

    /**
     * Handle incoming chunk
     */
    function handleChunk(providerType, chunk, onChunk) {
        try {
            const deltas = ProviderAdapters.parseDelta(providerType, chunk);
            for (let i = 0; i < deltas.length; i++) {
                const delta = deltas[i];
                if (delta.type === "text") {
                    chunkReceived(delta.content);
                    if (onChunk) {
                        onChunk(delta.content);
                    }
                } else if (delta.type === "done") {
                    // Stream finished
                }
            }
        } catch (e) {
            console.error("[StreamingService] Error parsing chunk:", e);
        }
    }

    /**
     * Handle stream completion
     */
    function handleDone(status, onDone) {
        isStreaming = false;
        currentXhr = null;
        streamFinished();
        if (onDone) {
            onDone(status);
        }
        console.log("[StreamingService] Stream finished with status:", status);
    }

    /**
     * Handle stream error
     */
    function handleError(error, onError) {
        isStreaming = false;
        currentError = error;
        currentXhr = null;
        streamError(error);
        if (onError) {
            onError(error);
        }
        console.error("[StreamingService] Stream error:", error);
    }

    /**
     * Cancel current stream
     */
    function cancel() {
        timeoutTimer.stop();
        if (currentXhr) {
            currentXhr.abort();
            currentXhr = null;
        }
        isStreaming = false;
        streamCancelled();
        console.log("[StreamingService] Stream cancelled");
    }

    /**
     * Check if currently streaming
     */
    function getIsStreaming() {
        return isStreaming;
    }

    /**
     * Get last error
     */
    function getLastError() {
        return currentError;
    }
}


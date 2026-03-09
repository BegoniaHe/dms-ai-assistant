.pragma library

/**
 * ProviderAdapters - Refactored provider adapters for multi-instance system
 * Supports: openai-v1-compatible, anthropic, gemini
 * v3 uses XMLHttpRequest for streaming (no external dependencies)
 */

function normalizeBaseUrl(url) {
    var u = (url || "").trim();
    if (!u)
        return "";
    return u.endsWith("/") ? u.slice(0, -1) : u;
}

function openaiChatCompletionsUrl(baseUrl) {
    var b = normalizeBaseUrl(baseUrl || "https://api.openai.com");
    if (/\/v\d+$/.test(b))
        return b + "/chat/completions";
    return b + "/v1/chat/completions";
}

/**
 * Send streaming XHR request
 * providerType: "openai-v1-compatible" | "anthropic" | "gemini"
 * onChunk(text): called for each chunk of data received
 * onDone(status): called when request completes successfully
 * onError(message): called on error
 * Returns: XMLHttpRequest object (can call .abort() to cancel)
 * Note: Timeout handling must be done by caller using Timer (Qt QML doesn't support xhr.timeout)
 */
function sendStreamRequest(providerType, payload, apiKey, onChunk, onDone, onError) {
    var req = buildRequest(providerType, payload, apiKey);
    if (!req || !req.url) {
        onError("Failed to build request");
        return null;
    }

    var xhr = new XMLHttpRequest();
    var offset = 0;

    xhr.onreadystatechange = function() {
        if (xhr.readyState === 3) {
            // LOADING - streaming data arriving
            var chunk = xhr.responseText.slice(offset);
            offset = xhr.responseText.length;
            if (chunk.length > 0) {
                onChunk(chunk);
            }
        }
        if (xhr.readyState === 4) {
            // DONE - request complete
            if (xhr.status === 0) {
                onError("Network error or connection refused");
            } else if (xhr.status !== 200) {
                var errorMsg = "HTTP " + xhr.status;
                try {
                    var errorData = JSON.parse(xhr.responseText);
                    if (errorData.error && errorData.error.message) {
                        errorMsg += ": " + errorData.error.message;
                    }
                } catch (e) {
                    // Ignore parse errors
                }
                onError(errorMsg);
            } else {
                onDone(xhr.status);
            }
        }
    };

    xhr.onerror = function() {
        onError("Network error");
    };

    xhr.open("POST", req.url, true);

    // Set headers
    for (var i = 0; i < req.headers.length; i++) {
        var h = req.headers[i];
        xhr.setRequestHeader(h.key, h.value);
    }

    xhr.send(req.body);
    return xhr;
}

/**
 * Build request for specific provider type
 */
function buildRequest(providerType, payload, apiKey) {
    switch (providerType) {
    case "anthropic":
        return anthropicRequest(payload, apiKey);
    case "gemini":
        return geminiRequest(payload, apiKey);
    case "openai-v1-compatible":
        return openaiRequest(payload, apiKey);
    default:
        // Fallback to OpenAI-compatible
        return openaiRequest(payload, apiKey);
    }
}

/**
 * OpenAI v1 Compatible request (OpenAI, LocalAI, Ollama, etc.)
 */
function openaiRequest(payload, apiKey) {
    var url = openaiChatCompletionsUrl(payload.baseUrl || "https://api.openai.com");
    var headers = [
        { key: "Content-Type", value: "application/json" },
        { key: "Authorization", value: "Bearer " + apiKey }
    ];
    var body = {
        model: payload.model,
        messages: payload.messages,
        max_tokens: payload.max_tokens || 1024,
        temperature: payload.temperature || 0.7,
        stream: true
    };
    return { url: url, headers: headers, body: JSON.stringify(body) };
}

/**
 * Anthropic request
 */
function anthropicRequest(payload, apiKey) {
    var url = (payload.baseUrl || "https://api.anthropic.com") + "/v1/messages";
    var headers = [
        { key: "Content-Type", value: "application/json" },
        { key: "x-api-key", value: apiKey },
        { key: "anthropic-version", value: "2023-06-01" }
    ];
    var body = {
        model: payload.model,
        messages: payload.messages.map(function(m) {
            return {
                role: m.role === "assistant" ? "assistant" : "user",
                content: m.content
            };
        }),
        max_tokens: payload.max_tokens || 1024,
        temperature: payload.temperature || 0.7,
        stream: true
    };
    return { url: url, headers: headers, body: JSON.stringify(body) };
}

/**
 * Gemini request
 */
function geminiRequest(payload, apiKey) {
    var url = (payload.baseUrl || "https://generativelanguage.googleapis.com")
        + "/v1beta/models/" + (payload.model || "gemini-2.5-flash") + ":streamGenerateContent"
        + "?key=" + apiKey + "&alt=sse";
    var headers = [
        { key: "Content-Type", value: "application/json" }
    ];
    var contents = payload.messages.map(function(m) {
        return {
            role: m.role === "user" ? "user" : "model",
            parts: [{ text: m.content }]
        };
    });
    var body = {
        contents: contents,
        generationConfig: {
            temperature: payload.temperature || 0.7,
            maxOutputTokens: payload.max_tokens || 1024
        }
    };
    return { url: url, headers: headers, body: JSON.stringify(body) };
}

/**
 * Parse delta from provider response
 * Returns: { type: "text" | "done", content: string }
 */
function parseDelta(providerType, chunk) {
    switch (providerType) {
    case "anthropic":
        return parseAnthropicDelta(chunk);
    case "gemini":
        return parseGeminiDelta(chunk);
    case "openai-v1-compatible":
        return parseOpenaiDelta(chunk);
    default:
        return parseOpenaiDelta(chunk);
    }
}

/**
 * Parse OpenAI SSE delta
 */
function parseOpenaiDelta(chunk) {
    var lines = chunk.split("\n");
    var result = [];

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line || !line.startsWith("data: "))
            continue;

        var data = line.substring(6);
        if (data === "[DONE]") {
            result.push({ type: "done", content: "" });
            continue;
        }

        try {
            var json = JSON.parse(data);
            if (json.choices && json.choices[0] && json.choices[0].delta) {
                var delta = json.choices[0].delta;
                if (delta.content) {
                    result.push({ type: "text", content: delta.content });
                }
            }
        } catch (e) {
            // Ignore parse errors
        }
    }

    return result;
}

/**
 * Parse Anthropic SSE delta
 */
function parseAnthropicDelta(chunk) {
    var lines = chunk.split("\n");
    var result = [];

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line || !line.startsWith("data: "))
            continue;

        var data = line.substring(6);
        try {
            var json = JSON.parse(data);
            if (json.type === "content_block_delta" && json.delta && json.delta.type === "text_delta") {
                result.push({ type: "text", content: json.delta.text });
            } else if (json.type === "message_stop") {
                result.push({ type: "done", content: "" });
            }
        } catch (e) {
            // Ignore parse errors
        }
    }

    return result;
}

/**
 * Parse Gemini SSE delta
 */
function parseGeminiDelta(chunk) {
    var lines = chunk.split("\n");
    var result = [];

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line || !line.startsWith("data: "))
            continue;

        var data = line.substring(6);
        try {
            var json = JSON.parse(data);
            if (json.candidates && json.candidates[0] && json.candidates[0].content) {
                var parts = json.candidates[0].content.parts;
                if (parts && parts[0] && parts[0].text) {
                    result.push({ type: "text", content: parts[0].text });
                }
            }
            if (json.candidates && json.candidates[0] && json.candidates[0].finishReason) {
                result.push({ type: "done", content: "" });
            }
        } catch (e) {
            // Ignore parse errors
        }
    }

    return result;
}

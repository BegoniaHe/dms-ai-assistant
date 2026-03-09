// QML JS library (not an ES module).
// Provider adapters for XHR streaming requests.
// v2 uses XMLHttpRequest instead of curl for better cross-platform support.
// Supports OpenAI-compatible, Anthropic, and Gemini streaming.

.pragma library

function normalizeBaseUrl(url) {
    var u = (url || "").trim();
    if (!u)
        return "";
    return u.endsWith("/") ? u.slice(0, -1) : u;
}

function openaiChatCompletionsUrl(baseUrl) {
    // Support the common OpenAI-style host base (https://api.openai.com -> /v1/chat/completions)
    // and versioned bases used by local servers or other providers (..../v1 or ..../v4 -> /chat/completions).
    var b = normalizeBaseUrl(baseUrl || "https://api.openai.com");
    if (/\/v\d+$/.test(b))
        return b + "/chat/completions";
    return b + "/v1/chat/completions";
}

// Send streaming XHR request
// onChunk(text): called for each chunk of data received
// onDone(status): called when request completes successfully
// onError(message): called on error
// Returns: XMLHttpRequest object (can call .abort() to cancel)
function sendStreamRequest(provider, payload, apiKey, onChunk, onDone, onError) {
    var req = buildRequest(provider, payload, apiKey);
    if (!req || !req.url) {
        onError("Failed to build request");
        return null;
    }

    var xhr = new XMLHttpRequest();
    var offset = 0;
    var timeoutMs = (payload.timeout || 30) * 1000;

    xhr.timeout = timeoutMs;

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

    xhr.ontimeout = function() {
        onError("Request timeout after " + (timeoutMs / 1000) + "s");
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

function buildRequest(provider, payload, apiKey) {
    switch (provider) {
    case "anthropic":
        return anthropicRequest(payload, apiKey);
    case "gemini":
        return geminiRequest(payload, apiKey);
    case "custom":
        return customRequest(payload, apiKey);
    default:
        return openaiRequest(payload, apiKey);
    }
}

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

function customRequest(payload, apiKey) {
    // v1 fallback: treat as OpenAI-compatible.
    return openaiRequest(payload, apiKey);
}

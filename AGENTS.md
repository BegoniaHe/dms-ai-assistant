# AGENTS.md

This file provides guidance for AI coding agents working with this repository.

## Project Summary

DMS AI Assistant - A QML/JavaScript plugin for DankMaterialShell providing multi-provider AI chat with streaming responses and markdown rendering.

**Repository**: https://github.com/devnullvoid/dms-ai-assistant
**Language**: QML + JavaScript (Qt 6.x)
**Runtime**: Quickshell (no build system - interpreted at runtime)

## Quick Start

```bash
# Run with debug logging (recommended for development)
QS_FORCE_STDERR_LOGGING=1 DMS_LOG_LEVEL=debug dms run

# Restart DMS to reload plugin changes
dms restart

# Check plugin settings
cat ~/.config/DankMaterialShell/plugin_settings.json | jq .aiAssistant
```

## Architecture Overview

**Pattern**: MVVM (Model-View-ViewModel) with clean separation of concerns

**Layers**:

1. **View Layer** (`views/`)
   - `AIAssistantView.qml` - Main chat interface
   - `SettingsView.qml` - Provider management UI
   - `MessageList.qml` - Message list container
   - `MessageBubble.qml` - Individual message component

2. **ViewModel Layer** (`viewmodels/`)
   - `ChatViewModel.qml` - Chat UI state and commands
   - `SettingsViewModel.qml` - Settings UI state and provider management

3. **Service Layer** (`services/`)
   - `ChatService.qml` - Core chat logic and message orchestration
   - `ProviderService.qml` - Multi-instance provider management
   - `SessionService.qml` - Chat history per provider instance
   - `StreamingService.qml` - XHR streaming lifecycle

4. **Data Access Layer** (`data/`)
   - `repositories/SettingsRepository.qml` - Settings persistence
   - `repositories/SessionRepository.qml` - Session persistence
   - `api/ProviderAdapters.js` - Provider-specific request builders
   - `utils/UUID.js` - UUID generation

**Entry Point**: `AIAssistantDaemon.qml` - Wires all layers together

**HTTP Method**: Uses native QML `XMLHttpRequest` for streaming SSE responses. Output streamed via `readyState=3` callbacks.

## Critical Implementation Notes

### Streaming Behavior (IMPORTANT)

**v2.0 XHR Implementation**:

- Uses native QML `XMLHttpRequest` instead of external curl process
- Streaming works via `readyState=3` (LOADING) callbacks
- Each callback receives incremental `responseText` chunks
- No external dependencies required - pure Qt6 QML implementation
- Cross-platform compatible (no Windows curl.exe issues)

**Why there's no "typing effect"**:

- Stream chunks ARE processed incrementally (thousands per response)
- QML batches property updates per render frame (~60fps) for performance
- Chunks arrive faster than UI can render individual updates
- Content appears "all at once" but is captured correctly
- **This is intentional QML behavior, not a bug**

### Provider System (v3 - Multi-Instance)

**Provider Types** (3 types, unlimited instances):

- `openai-v1-compatible` - OpenAI API v1 compatible (OpenAI, LocalAI, Ollama, etc.)
- `anthropic` - Anthropic Claude API
- `gemini` - Google Gemini API

**Provider Instance Structure**:

```javascript
{
  "id": "pid-1234567890-abc123def",
  "name": "OpenAI Production",
  "type": "openai-v1-compatible",
  "baseUrl": "https://api.openai.com",
  "model": "gpt-5.2",
  "apiKey": "",
  "saveApiKey": false,
  "apiKeyEnvVar": "OPENAI_API_KEY",
  "temperature": 0.7,
  "maxTokens": 4096,
  "timeout": 30,
  "createdAt": 1773079137937,
  "updatedAt": 1773079137937
}
```

**Settings File** (`~/.config/DankMaterialShell/plugin_settings.json`):

```javascript
{
  "aiAssistant": {
    "version": 3,
    "activeProviderId": "pid-1234567890-abc123def",
    "providerInstances": {
      "pid-1234567890-abc123def": { /* instance */ },
      "pid-9876543210-xyz789uvw": { /* instance */ }
    },
    "useMonospace": false
  }
}
```

**Session File** (`~/.local/state/DankMaterialShell/plugins/aiAssistant/session.json`):

```javascript
{
  "version": 3,
  "activeInstanceId": "pid-1234567890-abc123def",
  "sessions": {
    "pid-1234567890-abc123def": [
      { "id": "msg-...", "role": "user", "content": "...", "timestamp": 123, "status": "ok" },
      { "id": "msg-...", "role": "assistant", "content": "...", "timestamp": 124, "status": "ok" }
    ]
  }
}
```

**API Key Resolution Order**:

1. Session key (in-memory, not persisted)
2. Saved key (if `saveApiKey` is true)
3. Environment variable (from `apiKeyEnvVar` setting)
4. Fallback to empty string (user must configure)

## Debug Logging

With `QS_FORCE_STDERR_LOGGING=1 DMS_LOG_LEVEL=debug dms run`, watch for:

- `[ProviderService]` - Provider instance management
- `[ChatService]` - Message sending and streaming
- `[SessionService]` - Session loading/saving
- `[StreamingService]` - XHR lifecycle and errors
- `[SettingsRepository]` - Settings persistence
- `[SessionRepository]` - Session persistence

**Example debug session**:

```
[ProviderService] Loaded 2 provider instances
[ProviderService] Activated instance: pid-1234567890-abc123def
[SessionService] Loaded 5 messages for instance: pid-1234567890-abc123def
[ChatService] Sent user message: msg-...
[StreamingService] Starting stream for instance: pid-1234567890-abc123def type: openai-v1-compatible
[StreamingService] Stream finished with status: 200
[ChatService] Stream finished, received 1234 chars
```

## Common Pitfalls

1. **Empty responses** → Check network connectivity and API key validity
2. **"No API key" errors** → DMS daemon doesn't inherit shell environment vars; use saved key or systemd environment.d
3. **401 errors** → Verify API key has no whitespace; check provider authentication format
4. **QtQuick.Controls incompatibility** → Use custom QML implementations (MouseArea + Rectangle) instead of Menu/Popup
5. **Timeout errors** → Default timeout is 30s; increase via settings if needed for long responses
6. **Provider instance not found** → Ensure active provider ID is valid; check settings file
7. **Session history lost** → Verify session file permissions and storage location
8. **Streaming not working** → Check provider type matches request format; verify API endpoint

## Testing Checklist

- [ ] Settings persist across `dms restart`
- [ ] Chat history survives restart (if provider config unchanged)
- [ ] All providers work with real API keys
- [ ] Streaming displays content (even if all-at-once)
- [ ] Error messages appear for invalid keys
- [ ] Config changes clear chat history appropriately
- [ ] Markdown renders correctly (headers, code blocks, tables, lists, etc.)
- [ ] No QML errors in debug output

## Version History

- **3.0.0** (2026-03-09): MVVM refactoring + multi-instance provider system
  - Clean MVVM architecture (View → ViewModel → Service → Data Access)
  - Multi-instance provider support (unlimited instances, 3 types)
  - Improved code organization and maintainability
  - Better separation of concerns
- **2.0.0** (2026-03-09): Migrated from curl to native XHR for streaming, removed external dependencies
- **1.1.1** (2026-02-12): Fixed streaming by removing `--compressed` curl flag
- **1.1.0**: Initial release with multi-provider support

## File Modification Guidelines

- **No build needed** - Changes take effect after DMS restart
- **Read before editing** - Always read files first to understand context
- **Test with debug logging** - Run `QS_FORCE_STDERR_LOGGING=1 DMS_LOG_LEVEL=debug dms run`
- **Avoid QtQuick.Controls** - Not compatible with Quickshell runtime

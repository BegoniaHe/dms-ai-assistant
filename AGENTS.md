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

**Pattern**: Daemon + Slideout (singleton service + per-screen UI instances)

**Key Files**:

- `AIAssistantDaemon.qml` - Plugin lifecycle and screen management
- `AIAssistantService.qml` - Singleton backend service (API calls, streaming, state)
- `AIAssistant.qml` - UI component (chat interface)
- `AIApiAdapters.js` - Provider adapters and XHR streaming implementation
- `markdown2html.js` - Markdown to HTML converter

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

### Provider Configuration

**Supported Providers**:

- OpenAI (gpt-5.2 models)
- Anthropic (claude-4.5 models)
- Google Gemini (gemini-2.5-flash, gemini-3-flash-preview)
- Custom (OpenAI-compatible endpoints)

**Custom Provider Notes**:

- Treated as OpenAI-compatible
- Base URLs ending with `/v4` or `/v1` are handled correctly
- Example: `https://api.z.ai/api/coding/paas/v4` → appends `/chat/completions`
- Authentication via `Authorization: Bearer` header

### Settings Persistence

**IMPORTANT**: Must hardcode `pluginId: "aiAssistant"` instead of using injected `pluginService.pluginId` because PluginService injection happens after `Component.onCompleted`.

**API Key Resolution Order**:

1. Session key (in-memory, not persisted)
2. Saved key (if `saveApiKey` is true)
3. Custom env var (from `apiKeyEnvVar` setting)
4. Provider-specific env var (`<PROVIDER>_API_KEY`)
5. Scoped env var (`DMS_<PROVIDER>_API_KEY`)

## Debug Logging

With `DMS_LOG_LEVEL=debug`, watch for:

- `[AIAssistantService] request provider=` - Verify URL construction
- `[AIAssistantService] request body(preview)=` - Verify message format
- `[AIAssistantService] response finalized chars=` - Verify content capture

**Note**: Stream chunk logging is intentionally disabled (would produce thousands of lines per response).

## Common Pitfalls

1. **Empty responses** → Check network connectivity and API key validity
2. **"No API key" errors** → DMS daemon doesn't inherit shell environment vars; use saved key or systemd environment.d
3. **401 errors** → Verify API key has no whitespace; check provider authentication format
4. **QtQuick.Controls incompatibility** → Use custom QML implementations (MouseArea + Rectangle) instead of Menu/Popup
5. **Timeout errors** → Default timeout is 30s; increase via settings if needed for long responses

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

- **2.0.0** (2026-03-09): Migrated from curl to native XHR for streaming, removed external dependencies
- **1.1.1** (2026-02-12): Fixed streaming by removing `--compressed` curl flag
- **1.1.0**: Initial release with multi-provider support

## File Modification Guidelines

- **No build needed** - Changes take effect after DMS restart
- **Read before editing** - Always read files first to understand context
- **Test with debug logging** - Run `QS_FORCE_STDERR_LOGGING=1 DMS_LOG_LEVEL=debug dms run`
- **Avoid QtQuick.Controls** - Not compatible with Quickshell runtime

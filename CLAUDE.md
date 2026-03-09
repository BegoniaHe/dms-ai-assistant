# CLAUDE.md

> **Note**: Full documentation for AI agents is in [AGENTS.md](./AGENTS.md).

## Quick Reference

**Project**: DMS AI Assistant plugin (QML/JavaScript, no build system)
**Architecture**: MVVM (v3.0.0 - 2026-03-09)
**Provider System**: Multi-instance (3 types, unlimited instances)
**Testing**: `QS_FORCE_STDERR_LOGGING=1 DMS_LOG_LEVEL=debug dms run`

## Key Changes (v3.0.0)

- **MVVM Architecture**: Clean separation into View → ViewModel → Service → Data Access layers
- **Multi-Instance Providers**: Users can create unlimited provider instances (OpenAI, Anthropic, Gemini)
- **Improved Organization**: Code organized into `views/`, `viewmodels/`, `services/`, `data/` directories
- **Better Maintainability**: Single responsibility principle, easier to test and extend

## File Structure

```
dms-ai-assistant/
├── AIAssistantDaemon.qml      # Entry point (wires all layers)
├── views/                      # UI components
│   ├── AIAssistantView.qml
│   ├── SettingsView.qml
│   ├── MessageList.qml
│   └── MessageBubble.qml
├── viewmodels/                 # UI state & commands
│   ├── ChatViewModel.qml
│   └── SettingsViewModel.qml
├── services/                   # Business logic
│   ├── ChatService.qml
│   ├── ProviderService.qml
│   ├── SessionService.qml
│   └── StreamingService.qml
└── data/                       # Data access
    ├── repositories/
    ├── api/
    └── utils/
```

See [AGENTS.md](./AGENTS.md) for complete documentation.

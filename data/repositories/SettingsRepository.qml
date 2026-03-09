import QtQuick
import Quickshell
import qs.Services

/**
 * SettingsRepository - Wrapper around PluginService for settings persistence
 * Handles loading, saving, and migrating settings
 */
Item {
    id: root

    required property string pluginId

    // Default settings structure (version 3)
    readonly property var defaultSettings: ({
        version: 3,
        activeProviderId: "",
        providerInstances: {},
        useMonospace: false
    })

    /**
     * Load all settings
     */
    function loadAll() {
        const settings = PluginService.loadSettings(pluginId);
        if (!settings || Object.keys(settings).length === 0) {
            return Object.assign({}, defaultSettings);
        }
        return settings;
    }

    /**
     * Save all settings
     */
    function saveAll(settings) {
        PluginService.saveSettings(pluginId, settings);
    }

    /**
     * Load a specific setting by key
     */
    function load(key) {
        const settings = loadAll();
        return settings[key];
    }

    /**
     * Save a specific setting by key
     */
    function save(key, value) {
        const settings = loadAll();
        settings[key] = value;
        saveAll(settings);
    }

    /**
     * Create default provider instance
     */
    function createDefaultInstance(type, name) {
        return {
            id: "",  // Will be set by caller
            name: name || type,
            type: type,
            baseUrl: getDefaultBaseUrl(type),
            model: getDefaultModel(type),
            apiKey: "",
            saveApiKey: false,
            apiKeyEnvVar: getDefaultEnvVar(type),
            temperature: 0.7,
            maxTokens: 4096,
            timeout: 30,
            createdAt: Date.now(),
            updatedAt: Date.now()
        };
    }

    /**
     * Get default base URL for provider type
     */
    function getDefaultBaseUrl(type) {
        const defaults = {
            "openai-v1-compatible": "https://api.openai.com",
            "anthropic": "https://api.anthropic.com",
            "gemini": "https://generativelanguage.googleapis.com"
        };
        return defaults[type] || "";
    }

    /**
     * Get default model for provider type
     */
    function getDefaultModel(type) {
        const defaults = {
            "openai-v1-compatible": "gpt-5.2",
            "anthropic": "claude-sonnet-4-5",
            "gemini": "gemini-3-flash"
        };
        return defaults[type] || "";
    }

    /**
     * Get default environment variable for provider type
     */
    function getDefaultEnvVar(type) {
        const defaults = {
            "openai-v1-compatible": "OPENAI_API_KEY",
            "anthropic": "ANTHROPIC_API_KEY",
            "gemini": "GOOGLE_API_KEY"
        };
        return defaults[type] || "";
    }
}

import QtQuick
import "../data/repositories"
import "../data/utils/UUID.js" as UUID

/**
 * ProviderService - Manages provider instances and configuration
 * Handles CRUD operations, activation, and API key resolution
 */
Item {
    id: root

    required property var settingsRepository

    // Provider instances map: { id: { id, name, type, baseUrl, model, ... } }
    property var providerInstances: ({})
    property string activeProviderId: ""

    // Signals
    signal instanceCreated(string id)
    signal instanceUpdated(string id)
    signal instanceDeleted(string id)
    signal instanceActivated(string id)

    Component.onCompleted: {
        loadInstances();
    }

    /**
     * Load provider instances from settings
     */
    function loadInstances() {
        const settings = settingsRepository.loadAll();

        // Initialize with default structure if needed
        if (!settings.providerInstances || Object.keys(settings.providerInstances).length === 0) {
            // Create default OpenAI instance
            const defaultId = UUID.generateUUID();
            const defaultInstance = settingsRepository.createDefaultInstance("openai-v1-compatible", "OpenAI");
            defaultInstance.id = defaultId;

            const instances = {};
            instances[defaultId] = defaultInstance;

            settings.version = 3;
            settings.activeProviderId = defaultId;
            settings.providerInstances = instances;

            settingsRepository.saveAll(settings);
        }

        providerInstances = settings.providerInstances || {};
        activeProviderId = settings.activeProviderId || "";

        // Validate active instance exists
        if (!providerInstances[activeProviderId]) {
            const ids = Object.keys(providerInstances);
            activeProviderId = ids.length > 0 ? ids[0] : "";
        }

        console.log("[ProviderService] Loaded", Object.keys(providerInstances).length, "provider instances");
    }

    /**
     * Create a new provider instance
     */
    function createInstance(name, type, config) {
        const id = UUID.generateUUID();
        const instance = {
            id: id,
            name: name || type,
            type: type,
            baseUrl: config.baseUrl || settingsRepository.getDefaultBaseUrl(type),
            model: config.model || settingsRepository.getDefaultModel(type),
            apiKey: config.apiKey || "",
            saveApiKey: config.saveApiKey !== undefined ? config.saveApiKey : false,
            apiKeyEnvVar: config.apiKeyEnvVar || settingsRepository.getDefaultEnvVar(type),
            temperature: config.temperature !== undefined ? config.temperature : 0.7,
            maxTokens: config.maxTokens || 4096,
            timeout: config.timeout || 30,
            createdAt: Date.now(),
            updatedAt: Date.now()
        };

        const next = Object.assign({}, providerInstances);
        next[id] = instance;
        providerInstances = next;

        settingsRepository.save("providerInstances", next);
        instanceCreated(id);

        console.log("[ProviderService] Created instance:", id, "type:", type);
        return id;
    }

    /**
     * Update an existing provider instance
     */
    function updateInstance(id, updates) {
        if (!providerInstances[id]) {
            console.error("[ProviderService] Instance not found:", id);
            return;
        }

        const next = Object.assign({}, providerInstances);
        next[id] = Object.assign({}, next[id], updates, { updatedAt: Date.now() });

        providerInstances = next;
        settingsRepository.save("providerInstances", next);
        instanceUpdated(id);

        console.log("[ProviderService] Updated instance:", id);
    }

    /**
     * Delete a provider instance
     */
    function deleteInstance(id) {
        if (id === activeProviderId) {
            console.error("[ProviderService] Cannot delete active provider");
            return false;
        }

        if (!providerInstances[id]) {
            console.error("[ProviderService] Instance not found:", id);
            return false;
        }

        const next = Object.assign({}, providerInstances);
        delete next[id];
        providerInstances = next;

        settingsRepository.save("providerInstances", next);
        instanceDeleted(id);

        console.log("[ProviderService] Deleted instance:", id);
        return true;
    }

    /**
     * Activate a provider instance
     */
    function activateInstance(id) {
        if (!providerInstances[id]) {
            console.error("[ProviderService] Instance not found:", id);
            return;
        }

        activeProviderId = id;
        settingsRepository.save("activeProviderId", id);
        instanceActivated(id);

        console.log("[ProviderService] Activated instance:", id);
    }

    /**
     * Get the active provider instance
     */
    function getActiveInstance() {
        return providerInstances[activeProviderId] || null;
    }

    /**
     * Get a provider instance by ID
     */
    function getInstance(id) {
        return providerInstances[id] || null;
    }

    /**
     * Get provider type for an instance
     */
    function getInstanceType(id) {
        const instance = providerInstances[id || activeProviderId];
        return instance ? instance.type : null;
    }

    /**
     * Get all provider instances as array
     */
    function getAllInstances() {
        const result = [];
        for (const id in providerInstances) {
            result.push(providerInstances[id]);
        }
        return result;
    }

    /**
     * Resolve API key for an instance
     * Priority: session → saved → custom env var → provider env var → scoped env var
     */
    function resolveApiKey(instanceId, sessionKey) {
        const instance = providerInstances[instanceId || activeProviderId];
        if (!instance) {
            return "";
        }

        // 1. Session key (passed in)
        if (sessionKey) {
            return sessionKey;
        }

        // 2. Saved API key
        if (instance.apiKey && instance.saveApiKey) {
            return instance.apiKey;
        }

        // 3. Environment variable
        if (instance.apiKeyEnvVar) {
            const envValue = Qt.getenv(instance.apiKeyEnvVar);
            if (envValue) {
                return envValue;
            }
        }

        return "";
    }

    /**
     * Check if active instance has API key configured
     */
    function hasApiKey() {
        const instance = getActiveInstance();
        if (!instance) {
            return false;
        }

        if (instance.apiKey && instance.saveApiKey) {
            return true;
        }

        if (instance.apiKeyEnvVar) {
            const envValue = Qt.getenv(instance.apiKeyEnvVar);
            if (envValue) {
                return true;
            }
        }

        return false;
    }
}

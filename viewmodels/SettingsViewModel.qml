import QtQuick

/**
 * SettingsViewModel - Manages settings UI state and commands
 * Handles provider management, add/edit/delete dialogs
 */
Item {
    id: root

    required property var providerService
    required property var settingsRepository

    // Expose provider data to View
    readonly property var providerInstances: providerService.providerInstances
    readonly property string activeProviderId: providerService.activeProviderId
    readonly property var activeInstance: providerService.getActiveInstance()

    // Dialog state
    property bool showAddDialog: false
    property bool showEditDialog: false
    property bool showDeleteDialog: false
    property string editingInstanceId: ""

    // Form state
    property string formName: ""
    property string formType: "openai-v1-compatible"
    property string formBaseUrl: ""
    property string formModel: ""
    property string formApiKey: ""
    property bool formSaveApiKey: false
    property string formApiKeyEnvVar: ""
    property real formTemperature: 0.7
    property int formMaxTokens: 4096
    property int formTimeout: 30

    // Provider templates
    readonly property var providerTemplates: ({
        "openai-gpt52": {
            name: "OpenAI GPT-5.2",
            type: "openai-v1-compatible",
            baseUrl: "https://api.openai.com",
            model: "gpt-5.2",
            temperature: 0.7,
            maxTokens: 4096,
            timeout: 30
        },
        "anthropic-sonnet": {
            name: "Anthropic Claude Sonnet",
            type: "anthropic",
            baseUrl: "https://api.anthropic.com",
            model: "claude-sonnet-4-5",
            temperature: 1.0,
            maxTokens: 4096,
            timeout: 30
        },
        "gemini-flash": {
            name: "Google Gemini Flash",
            type: "gemini",
            baseUrl: "https://generativelanguage.googleapis.com",
            model: "gemini-3-flash",
            temperature: 0.7,
            maxTokens: 4096,
            timeout: 30
        },
        "local-ollama": {
            name: "Local Ollama",
            type: "openai-v1-compatible",
            baseUrl: "http://localhost:11434/v1",
            model: "llama3.2",
            temperature: 0.7,
            maxTokens: 2048,
            timeout: 60
        }
    })

    /**
     * Open add provider dialog
     */
    function openAddDialog() {
        resetForm();
        showAddDialog = true;
    }

    /**
     * Open edit provider dialog
     */
    function openEditDialog(instanceId) {
        const instance = providerService.getInstance(instanceId);
        if (!instance) {
            console.warn("[SettingsViewModel] Instance not found:", instanceId);
            return;
        }

        editingInstanceId = instanceId;
        formName = instance.name;
        formType = instance.type;
        formBaseUrl = instance.baseUrl;
        formModel = instance.model;
        formApiKey = instance.apiKey || "";
        formSaveApiKey = instance.saveApiKey;
        formApiKeyEnvVar = instance.apiKeyEnvVar;
        formTemperature = instance.temperature;
        formMaxTokens = instance.maxTokens;
        formTimeout = instance.timeout;

        showEditDialog = true;
    }

    /**
     * Open delete confirmation dialog
     */
    function openDeleteDialog(instanceId) {
        editingInstanceId = instanceId;
        showDeleteDialog = true;
    }

    /**
     * Close all dialogs
     */
    function closeDialogs() {
        showAddDialog = false;
        showEditDialog = false;
        showDeleteDialog = false;
        resetForm();
    }

    /**
     * Reset form to defaults
     */
    function resetForm() {
        editingInstanceId = "";
        formName = "";
        formType = "openai-v1-compatible";
        formBaseUrl = settingsRepository.getDefaultBaseUrl("openai-v1-compatible");
        formModel = settingsRepository.getDefaultModel("openai-v1-compatible");
        formApiKey = "";
        formSaveApiKey = false;
        formApiKeyEnvVar = settingsRepository.getDefaultEnvVar("openai-v1-compatible");
        formTemperature = 0.7;
        formMaxTokens = 4096;
        formTimeout = 30;
    }

    /**
     * Update form base URL when type changes
     */
    function updateFormDefaults() {
        formBaseUrl = settingsRepository.getDefaultBaseUrl(formType);
        formModel = settingsRepository.getDefaultModel(formType);
        formApiKeyEnvVar = settingsRepository.getDefaultEnvVar(formType);
    }

    /**
     * Apply template
     */
    function applyTemplate(templateKey) {
        const template = providerTemplates[templateKey];
        if (!template) {
            console.warn("[SettingsViewModel] Template not found:", templateKey);
            return;
        }

        formName = template.name;
        formType = template.type;
        formBaseUrl = template.baseUrl;
        formModel = template.model;
        formTemperature = template.temperature;
        formMaxTokens = template.maxTokens;
        formTimeout = template.timeout;
    }

    /**
     * Create new provider instance
     */
    function createProvider() {
        if (!formName || formName.trim().length === 0) {
            console.warn("[SettingsViewModel] Provider name required");
            return false;
        }

        const id = providerService.createInstance(
            formName.trim(),
            formType,
            {
                baseUrl: formBaseUrl,
                model: formModel,
                apiKey: formApiKey,
                saveApiKey: formSaveApiKey,
                apiKeyEnvVar: formApiKeyEnvVar,
                temperature: formTemperature,
                maxTokens: formMaxTokens,
                timeout: formTimeout
            }
        );

        closeDialogs();
        console.log("[SettingsViewModel] Created provider:", id);
        return true;
    }

    /**
     * Update existing provider instance
     */
    function updateProvider() {
        if (!editingInstanceId) {
            console.warn("[SettingsViewModel] No instance selected");
            return false;
        }

        if (!formName || formName.trim().length === 0) {
            console.warn("[SettingsViewModel] Provider name required");
            return false;
        }

        providerService.updateInstance(editingInstanceId, {
            name: formName.trim(),
            type: formType,
            baseUrl: formBaseUrl,
            model: formModel,
            apiKey: formApiKey,
            saveApiKey: formSaveApiKey,
            apiKeyEnvVar: formApiKeyEnvVar,
            temperature: formTemperature,
            maxTokens: formMaxTokens,
            timeout: formTimeout
        });

        closeDialogs();
        console.log("[SettingsViewModel] Updated provider:", editingInstanceId);
        return true;
    }

    /**
     * Delete provider instance
     */
    function deleteProvider() {
        if (!editingInstanceId) {
            console.warn("[SettingsViewModel] No instance selected");
            return false;
        }

        const success = providerService.deleteInstance(editingInstanceId);
        if (success) {
            closeDialogs();
            console.log("[SettingsViewModel] Deleted provider:", editingInstanceId);
        }
        return success;
    }

    /**
     * Activate provider instance
     */
    function activateProvider(instanceId) {
        providerService.activateInstance(instanceId);
        console.log("[SettingsViewModel] Activated provider:", instanceId);
    }

    /**
     * Get all provider instances as array
     */
    function getAllInstances() {
        return providerService.getAllInstances();
    }

    /**
     * Check if instance is active
     */
    function isInstanceActive(instanceId) {
        return instanceId === activeProviderId;
    }

    /**
     * Get provider type display name
     */
    function getTypeDisplayName(type) {
        const names = {
            "openai-v1-compatible": "OpenAI v1 Compatible",
            "anthropic": "Anthropic",
            "gemini": "Google Gemini"
        };
        return names[type] || type;
    }

    /**
     * Validate form
     */
    function validateForm() {
        if (!formName || formName.trim().length === 0) {
            return { valid: false, error: "Provider name is required" };
        }
        if (!formBaseUrl || formBaseUrl.trim().length === 0) {
            return { valid: false, error: "Base URL is required" };
        }
        if (!formModel || formModel.trim().length === 0) {
            return { valid: false, error: "Model is required" };
        }
        return { valid: true, error: "" };
    }
}

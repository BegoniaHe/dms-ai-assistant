import QtQuick
import Quickshell

/**
 * SessionRepository - Wrapper around FileView for session persistence
 * Handles loading and saving chat history per provider instance
 */
Item {
    id: root

    required property string pluginId

    // Default session structure (version 3)
    readonly property var defaultSession: ({
        version: 3,
        activeInstanceId: "",
        sessions: {}
    })

    /**
     * Get session file path
     */
    function getSessionPath() {
        const stateDir = StandardPaths.writableLocation(StandardPaths.AppDataLocation);
        return stateDir + "/plugins/" + pluginId + "/session.json";
    }

    /**
     * Load all sessions
     */
    function loadAll() {
        try {
            const path = getSessionPath();
            const file = FileView.open(path);
            if (!file) {
                return Object.assign({}, defaultSession);
            }
            const content = file.read();
            file.close();
            if (!content) {
                return Object.assign({}, defaultSession);
            }
            return JSON.parse(content);
        } catch (e) {
            console.error("[SessionRepository] Error loading sessions:", e);
            return Object.assign({}, defaultSession);
        }
    }

    /**
     * Save all sessions
     */
    function saveAll(sessions) {
        try {
            const path = getSessionPath();
            const dir = path.substring(0, path.lastIndexOf("/"));

            // Ensure directory exists
            const dirFile = FileView.open(dir);
            if (!dirFile) {
                FileView.mkdir(dir);
            } else {
                dirFile.close();
            }

            const file = FileView.open(path, FileView.WriteOnly);
            if (!file) {
                console.error("[SessionRepository] Cannot open file for writing:", path);
                return;
            }
            file.write(JSON.stringify(sessions, null, 2));
            file.close();
        } catch (e) {
            console.error("[SessionRepository] Error saving sessions:", e);
        }
    }

    /**
     * Load messages for a specific instance
     */
    function loadMessages(instanceId) {
        const sessions = loadAll();
        return sessions.sessions[instanceId] || [];
    }

    /**
     * Save messages for a specific instance
     */
    function saveMessages(instanceId, messages) {
        const sessions = loadAll();
        sessions.sessions[instanceId] = messages;
        sessions.activeInstanceId = instanceId;
        saveAll(sessions);
    }

    /**
     * Delete messages for a specific instance
     */
    function deleteMessages(instanceId) {
        const sessions = loadAll();
        delete sessions.sessions[instanceId];
        saveAll(sessions);
    }

    /**
     * Clear all messages for a specific instance
     */
    function clearMessages(instanceId) {
        saveMessages(instanceId, []);
    }

    /**
     * Get active instance ID
     */
    function getActiveInstanceId() {
        const sessions = loadAll();
        return sessions.activeInstanceId || "";
    }

    /**
     * Set active instance ID
     */
    function setActiveInstanceId(instanceId) {
        const sessions = loadAll();
        sessions.activeInstanceId = instanceId;
        saveAll(sessions);
    }
}

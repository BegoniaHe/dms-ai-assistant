.pragma library

/**
 * Generate a simple UUID-like identifier
 * Format: pid-{timestamp}-{random}
 */
function generateUUID() {
    return "pid-" + Date.now() + "-" + Math.random().toString(36).slice(2, 11);
}

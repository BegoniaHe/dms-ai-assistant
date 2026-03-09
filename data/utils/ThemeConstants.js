/**
 * ThemeConstants.js - Centralized UI constants management
 * Eliminates hardcoded values and ensures consistency across the application
 */

const Sizes = {
    // Header and bars
    headerHeight: 48,  // Theme.barHeight
    composerHeight: 80,
    hintBarHeight: 32,

    // Buttons
    buttonSize: 32,
    buttonSizeSmall: 28,
    iconSize: 18,
    iconSizeSmall: 14,

    // Message bubble
    bubbleRadius: 8,
    bubblePadding: 12,
    bubbleHeaderHeight: 20,
    bubbleAvatarSize: 18,
    bubbleActionButtonSize: 24,
    bubbleActionIconSize: 14,

    // Dialogs
    dialogWidth: 400,
    dialogHeight: 500,
    deleteDialogWidth: 300,
    deleteDialogHeight: 150,

    // Popups
    settingsMenuWidth: 300,
    settingsMenuHeight: 400,
    overflowMenuWidth: 200,
    overflowMenuHeight: 150,

    // Provider list
    providerListItemHeight: 60,
    providerListItemPadding: 8,

    // Main window
    mainWindowWidth: 500,
    mainWindowHeight: 700,
};


const Animations = {
    // Durations (in milliseconds)
    hintDuration: 2500,
    streamUpdateInterval: 100,
    menuSlideInDuration: 200,  // Theme.shortDuration
    hintFadeDuration: 150,     // Theme.shorterDuration
    bubbleAnimationDuration: 120,

    // Scroll behavior
    scrollStickThreshold: 20,  // pixels from bottom to stick
};

const Layout = {
    // Main layout
    mainWidth: 500,
    mainHeight: 700,

    // Dialog sizes
    dialogWidth: 400,
    dialogHeight: 500,
    addDialogHeight: 500,
    editDialogHeight: 500,
    deleteDialogHeight: 150,

    // Menu sizes
    settingsMenuWidth: 300,
    settingsMenuHeight: 400,
    overflowMenuWidth: 200,
    overflowMenuHeight: 150,

    // Popup positioning offset
    popupOffsetX: 8,
    popupOffsetY: 48,
};

const MessageColors = {
    // User bubble
    userBubbleFill: "rgba(0, 0, 0, 0.1)",      // Theme.withAlpha(Theme.primary, 0.1)
    userBubbleBorder: "rgba(0, 0, 0, 0.3)",    // Theme.withAlpha(Theme.primary, 0.3)
    userBadgeBg: "rgba(0, 0, 0, 0.14)",        // Theme.withAlpha(Theme.primary, 0.14)
    userAvatarBg: "rgba(0, 0, 0, 0.20)",       // Theme.withAlpha(Theme.primary, 0.20)

    // Assistant bubble (uses Theme colors directly)
    // assistantBubbleFill: Theme.surfaceContainer
    // assistantBubbleBorder: Theme.outline

    // Error state
    // errorBorder: Theme.error
};

const Form = {
    // Field heights
    textFieldHeight: 40,
    textAreaHeight: 100,

    // Spacing
    fieldSpacing: 12,
    labelSpacing: 4,

    // Button sizes
    buttonHeight: 40,
    buttonSmallHeight: 28,
};

const Provider = {
    // Type display names
    typeNames: {
        "openai-v1-compatible": "OpenAI v1",
        "anthropic": "Anthropic",
        "gemini": "Gemini",
    },

    // Default values
    defaultTimeout: 30000,  // milliseconds
    defaultTemperature: 0.7,
    defaultMaxTokens: 2000,
};

var ThemeConstants = {
    Sizes,
    Animations,
    Layout,
    MessageColors,
    Form,
    Provider,
};

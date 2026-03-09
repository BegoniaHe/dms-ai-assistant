import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import "components"
import "../data/utils/ThemeConstants.js" as ThemeConstants

/**
 * SettingsView - Full-screen settings panel
 * Displays provider management and current provider configuration
 */
Rectangle {
    id: root

    required property var viewModel
    required property var providerService

    signal closed()

    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.98)
    radius: Theme.cornerRadius
    border.color: Theme.surfaceVariantAlpha
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Header with close button
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingL

            StyledText {
                text: "AI Assistant Settings"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            DankButton {
                text: "Close"
                iconName: "close"
                onClicked: root.closed()
            }
        }

        // Scrollable content area
        DankFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: settingsColumn.implicitHeight + Theme.spacingXL
            contentWidth: width

            Column {
                id: settingsColumn
                width: Math.min(550, parent.width - Theme.spacingL * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingL

                // Provider Management Card
                Rectangle {
                    width: parent.width
                    height: providerContent.height + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    Column {
                        id: providerContent
                        width: parent.width - Theme.spacingL * 2
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        // Header
                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "cloud"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "Providers"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                Layout.fillWidth: true
                            }

                            DankButton {
                                text: "+ Add"
                                width: 60
                                height: 28
                                onClicked: viewModel.openAddDialog()
                            }
                        }

                        // Provider list
                        Column {
                            width: parent.width
                            spacing: Theme.spacingM

                            Repeater {
                                model: viewModel.getAllInstances()

                                delegate: ProviderListItem {
                                    width: parent.width
                                    providerData: modelData
                                    isActive: modelData.id === viewModel.activeProviderId

                                    onEditClicked: viewModel.openEditDialog(modelData.id)
                                    onDeleteClicked: viewModel.openDeleteDialog(modelData.id)
                                    onActivateClicked: viewModel.activateProvider(modelData.id)
                                }
                            }
                        }
                    }
                }

                // Provider Configuration Card
                Rectangle {
                    width: parent.width
                    height: providerConfigContent.height + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    Column {
                        id: providerConfigContent
                        width: parent.width - Theme.spacingL * 2
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "settings"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "Provider Configuration"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Base URL"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            DankTextField {
                                width: parent.width
                                placeholderText: "https://api.openai.com"
                                text: viewModel.formBaseUrl
                                onTextChanged: viewModel.formBaseUrl = text
                            }

                            StyledText {
                                text: "Model"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            DankTextField {
                                width: parent.width
                                placeholderText: "gpt-5.2"
                                text: viewModel.formModel
                                onTextChanged: viewModel.formModel = text
                            }
                        }
                    }
                }

                // API Key Card
                Rectangle {
                    width: parent.width
                    height: apiContent.height + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    Column {
                        id: apiContent
                        width: parent.width - Theme.spacingL * 2
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "vpn_key"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "API Authentication"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingS

                            StyledText {
                                text: "API Key"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            DankTextField {
                                width: parent.width
                                placeholderText: "Enter API key"
                                echoMode: TextInput.Password
                                text: viewModel.formApiKey
                                onTextChanged: viewModel.formApiKey = text
                            }

                            StyledText {
                                text: "API Key Env Var"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            DankTextField {
                                width: parent.width
                                placeholderText: "e.g. OPENAI_API_KEY"
                                text: viewModel.formApiKeyEnvVar
                                onTextChanged: viewModel.formApiKeyEnvVar = text
                            }

                            Item {
                                width: parent.width
                                height: Theme.spacingS
                            }

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "Remember API Key"
                                    Layout.fillWidth: true
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                }

                                DankToggle {
                                    checked: viewModel.formSaveApiKey
                                    onToggled: checked => viewModel.formSaveApiKey = checked
                                }
                            }
                        }
                    }
                }

                // Temperature Card
                Rectangle {
                    width: parent.width
                    height: tempContent.height + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    Column {
                        id: tempContent
                        width: parent.width - Theme.spacingL * 2
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "thermostat"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingXS
                                width: parent.width - parent.spacing - Theme.iconSize

                                StyledText {
                                    text: "Temperature: %1".arg(viewModel.formTemperature.toFixed(1))
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Controls randomness (0 = focused, 2 = creative)"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }
                        }

                        DankSlider {
                            width: parent.width
                            height: 32
                            minimum: 0
                            maximum: 20
                            value: Math.round(viewModel.formTemperature * 10)
                            showValue: false
                            onSliderValueChanged: newValue => viewModel.formTemperature = newValue / 10
                        }
                    }
                }

                // Max Tokens Card
                Rectangle {
                    width: parent.width
                    height: tokensContent.height + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    Column {
                        id: tokensContent
                        width: parent.width - Theme.spacingL * 2
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "data_usage"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingXS
                                width: parent.width - parent.spacing - Theme.iconSize

                                StyledText {
                                    text: "Max Tokens: %1".arg(viewModel.formMaxTokens)
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Maximum response length"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }
                        }

                        DankSlider {
                            width: parent.width
                            height: 32
                            minimum: 128
                            maximum: 32768
                            step: 256
                            value: viewModel.formMaxTokens
                            showValue: false
                            onSliderValueChanged: newValue => viewModel.formMaxTokens = newValue
                        }
                    }
                }

                // Display Options Card
                Rectangle {
                    width: parent.width
                    height: displayContent.height + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    Column {
                        id: displayContent
                        width: parent.width - Theme.spacingL * 2
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "code"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "Display Options"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item {
                            width: parent.width
                            height: Math.max(monoToggle.height, descColumn.height)

                            Column {
                                id: descColumn
                                anchors.left: parent.left
                                anchors.right: monoToggle.left
                                anchors.rightMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                StyledText {
                                    text: "Monospace Font"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Use monospace font for AI replies (better for code)"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }

                            DankToggle {
                                id: monoToggle
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                checked: viewModel.formUseMonospace
                                onToggled: checked => viewModel.formUseMonospace = checked
                            }
                        }
                    }
                }
            }
        }
    }

    // Add Provider Dialog
    Dialog {
        isVisible: viewModel.showAddDialog
        title: "Add Provider"
        dialogWidth: ThemeConstants.Layout.dialogWidth
        dialogHeight: ThemeConstants.Layout.addDialogHeight

        content: Component {
            ColumnLayout {
                spacing: Theme.spacingM
                anchors.fill: parent

                // Provider name
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "Provider Name"
                    text: viewModel.formName
                    onTextChanged: viewModel.formName = text
                }

                // Type selection
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Type:"
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        DankButton {
                            text: "OpenAI v1"
                            Layout.fillWidth: true
                            onClicked: {
                                viewModel.formType = "openai-v1-compatible";
                                viewModel.updateFormDefaults();
                            }
                        }

                        DankButton {
                            text: "Anthropic"
                            Layout.fillWidth: true
                            onClicked: {
                                viewModel.formType = "anthropic";
                                viewModel.updateFormDefaults();
                            }
                        }

                        DankButton {
                            text: "Gemini"
                            Layout.fillWidth: true
                            onClicked: {
                                viewModel.formType = "gemini";
                                viewModel.updateFormDefaults();
                            }
                        }
                    }
                }

                // Base URL
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "Base URL"
                    text: viewModel.formBaseUrl
                    onTextChanged: viewModel.formBaseUrl = text
                }

                // Model
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "Model"
                    text: viewModel.formModel
                    onTextChanged: viewModel.formModel = text
                }

                // API Key
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "API Key (optional)"
                    text: viewModel.formApiKey
                    onTextChanged: viewModel.formApiKey = text
                    echoMode: TextInput.Password
                }

                // Environment variable
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "Env Var"
                    text: viewModel.formApiKeyEnvVar
                    onTextChanged: viewModel.formApiKeyEnvVar = text
                }

                Item { Layout.fillHeight: true }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    DankButton {
                        text: "Cancel"
                        Layout.fillWidth: true
                        onClicked: viewModel.closeDialogs()
                    }

                    DankButton {
                        text: "Create"
                        Layout.fillWidth: true
                        onClicked: viewModel.createProvider()
                    }
                }
            }
        }

        onClosed: viewModel.closeDialogs()
    }

    // Edit Provider Dialog
    Dialog {
        isVisible: viewModel.showEditDialog
        title: "Edit Provider"
        dialogWidth: ThemeConstants.Layout.dialogWidth
        dialogHeight: ThemeConstants.Layout.editDialogHeight

        content: Component {
            ColumnLayout {
                spacing: Theme.spacingM
                anchors.fill: parent

                // Provider name
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "Provider Name"
                    text: viewModel.formName
                    onTextChanged: viewModel.formName = text
                }

                // Base URL
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "Base URL"
                    text: viewModel.formBaseUrl
                    onTextChanged: viewModel.formBaseUrl = text
                }

                // Model
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "Model"
                    text: viewModel.formModel
                    onTextChanged: viewModel.formModel = text
                }

                // API Key
                DankTextField {
                    Layout.fillWidth: true
                    placeholderText: "API Key (optional)"
                    text: viewModel.formApiKey
                    onTextChanged: viewModel.formApiKey = text
                    echoMode: TextInput.Password
                }

                Item { Layout.fillHeight: true }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    DankButton {
                        text: "Cancel"
                        Layout.fillWidth: true
                        onClicked: viewModel.closeDialogs()
                    }

                    DankButton {
                        text: "Update"
                        Layout.fillWidth: true
                        onClicked: viewModel.updateProvider()
                    }
                }
            }
        }

        onClosed: viewModel.closeDialogs()
    }

    // Delete Confirmation Dialog
    Dialog {
        isVisible: viewModel.showDeleteDialog
        title: "Delete Provider?"
        dialogWidth: ThemeConstants.Layout.deleteDialogWidth
        dialogHeight: ThemeConstants.Layout.deleteDialogHeight

        content: Component {
            ColumnLayout {
                spacing: Theme.spacingM
                anchors.fill: parent

                StyledText {
                    text: "This action cannot be undone."
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    DankButton {
                        text: "Cancel"
                        Layout.fillWidth: true
                        onClicked: viewModel.closeDialogs()
                    }

                    DankButton {
                        text: "Delete"
                        Layout.fillWidth: true
                        onClicked: viewModel.deleteProvider()
                    }
                }
            }
        }

        onClosed: viewModel.closeDialogs()
    }
}

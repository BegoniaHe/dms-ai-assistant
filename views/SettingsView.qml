import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets

/**
 * SettingsView - Settings panel for provider management
 */
Rectangle {
    id: root

    required property var viewModel
    required property var providerService

    signal closed()

    color: Theme.backgroundColor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: "Providers"
                font.bold: true
                font.pixelSize: 14
                Layout.fillWidth: true
            }

            DankButton {
                text: "+ Add"
                width: 60
                height: 28
                onClicked: viewModel.openAddDialog()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surfaceColor
            border.color: Theme.borderColor
            border.width: 1
            radius: 4

            ListView {
                id: providerList
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                clip: true

                model: viewModel.getAllInstances()

                delegate: Rectangle {
                    width: providerList.width - 16
                    height: 60
                    color: modelData.id === viewModel.activeProviderId ? Theme.accentColor : Theme.backgroundColor
                    border.color: Theme.borderColor
                    border.width: 1
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: modelData.name
                                font.bold: true
                                color: modelData.id === viewModel.activeProviderId ? "white" : Theme.textColor
                            }

                            StyledText {
                                text: viewModel.getTypeDisplayName(modelData.type) + " | " + modelData.model
                                font.pixelSize: 11
                                opacity: 0.7
                                color: modelData.id === viewModel.activeProviderId ? "white" : Theme.textColor
                            }
                        }

                        DankButton {
                            text: "Edit"
                            width: 50
                            height: 28
                            onClicked: viewModel.openEditDialog(modelData.id)
                        }

                        DankButton {
                            text: "Delete"
                            width: 60
                            height: 28
                            enabled: modelData.id !== viewModel.activeProviderId
                            onClicked: viewModel.openDeleteDialog(modelData.id)
                        }

                        DankButton {
                            text: "Use"
                            width: 50
                            height: 28
                            visible: modelData.id !== viewModel.activeProviderId
                            onClicked: viewModel.activateProvider(modelData.id)
                        }
                    }
                }
            }
        }

        DankButton {
            text: "Close"
            Layout.fillWidth: true
            onClicked: root.closed()
        }
    }

    Rectangle {
        id: addDialog
        visible: viewModel.showAddDialog
        width: 400
        height: 500
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        radius: 8
        z: 1000

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            StyledText {
                text: "Add Provider"
                font.bold: true
                font.pixelSize: 14
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "Provider Name"
                text: viewModel.formName
                onTextChanged: viewModel.formName = text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: "Type:"
                    font.pixelSize: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

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

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "Base URL"
                text: viewModel.formBaseUrl
                onTextChanged: viewModel.formBaseUrl = text
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "Model"
                text: viewModel.formModel
                onTextChanged: viewModel.formModel = text
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "API Key (optional)"
                text: viewModel.formApiKey
                onTextChanged: viewModel.formApiKey = text
                echoMode: TextInput.Password
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "Env Var"
                text: viewModel.formApiKeyEnvVar
                onTextChanged: viewModel.formApiKeyEnvVar = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

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

    Rectangle {
        id: editDialog
        visible: viewModel.showEditDialog
        width: 400
        height: 500
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        radius: 8
        z: 1000

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            StyledText {
                text: "Edit Provider"
                font.bold: true
                font.pixelSize: 14
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "Provider Name"
                text: viewModel.formName
                onTextChanged: viewModel.formName = text
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "Base URL"
                text: viewModel.formBaseUrl
                onTextChanged: viewModel.formBaseUrl = text
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "Model"
                text: viewModel.formModel
                onTextChanged: viewModel.formModel = text
            }

            DankTextField {
                Layout.fillWidth: true
                placeholderText: "API Key (optional)"
                text: viewModel.formApiKey
                onTextChanged: viewModel.formApiKey = text
                echoMode: TextInput.Password
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

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

    Rectangle {
        id: deleteDialog
        visible: viewModel.showDeleteDialog
        width: 300
        height: 150
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        radius: 8
        z: 1000

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            StyledText {
                text: "Delete Provider?"
                font.bold: true
            }

            StyledText {
                text: "This action cannot be undone."
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

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
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Widgets
import "data/repositories" as Repositories
import "services" as Services
import "viewmodels" as ViewModels
import "views" as Views

Item {
    id: root

    property var pluginService: null
    property string pluginId: "aiAssistant"

    function toggle() {
        if (variants.instances.length > 0) {
            variants.instances[0].toggle();
        }
    }

    Component.onCompleted: {
        console.log("[AIAssistantDaemon] MVVM Refactored v3.0.0 - Initialized");
    }

    Variants {
        id: variants
        model: Quickshell.screens

        delegate: DankSlideout {
            id: slideout
            required property var modelData
            title: "AI Assistant"
            slideoutWidth: 480
            expandable: true
            expandedWidthValue: 960

            // Data Layer - Repositories
            Repositories.SettingsRepository {
                id: settingsRepo
                pluginId: root.pluginId
            }

            Repositories.SessionRepository {
                id: sessionRepo
                pluginId: root.pluginId
            }

            // Service Layer
            Services.ProviderService {
                id: providerSvc
                settingsRepository: settingsRepo
            }

            Services.SessionService {
                id: sessionSvc
                sessionRepository: sessionRepo
            }

            Services.StreamingService {
                id: streamingSvc
                providerService: providerSvc
            }

            Services.ChatService {
                id: chatSvc
                providerService: providerSvc
                sessionService: sessionSvc
                streamingService: streamingSvc
            }

            // ViewModel Layer
            ViewModels.ChatViewModel {
                id: chatVM
                chatService: chatSvc
                providerService: providerSvc
                sessionService: sessionSvc
            }

            ViewModels.SettingsViewModel {
                id: settingsVM
                providerService: providerSvc
                settingsRepository: settingsRepo
            }

            // View Layer - Main Chat Interface
            content: Views.AIAssistantView {
                viewModel: chatVM
                settingsViewModel: settingsVM
                providerService: providerSvc
                sessionService: sessionSvc
                onHideRequested: slideout.hide()
            }
        }
    }
}



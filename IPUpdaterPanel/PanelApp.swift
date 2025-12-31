import SwiftUI

/// Foreground configuration panel.
/// User-launched only. No background execution.
/// Edits configuration and enables/disables agent via launchctl.
@main
struct PanelApp: App {
    @StateObject private var viewModel: PanelViewModel
    
    init() {
        let configManager = PanelConfigManager(configURL: PanelConfigManager.defaultConfigURL())
        let keychainManager = KeychainManager()
        let launchctlManager = LaunchctlManager()
        
        let vm = PanelViewModel(
            configManager: configManager,
            keychainManager: keychainManager,
            launchctlManager: launchctlManager
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some Scene {
        WindowGroup {
            PanelView(viewModel: viewModel)
                .frame(width: 500, height: 400)
                .onAppear {
                    viewModel.load()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}


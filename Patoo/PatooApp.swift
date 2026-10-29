//
//  PatooApp.swift
//  Patoo
//

import SwiftUI

@main
struct PatooApp: App {
    init() {
        #if DEBUG
        _ = CoreLogicTests.runAllTests()
        #endif
        
        // Check FFmpeg updates and installation on every app launch
        Task { @MainActor in
            FFmpegUpdateManager.shared.checkUpdateOnLaunch(appState: AppState.shared)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1040, height: 720)
    }
}

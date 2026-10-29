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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1040, height: 720)
    }
}

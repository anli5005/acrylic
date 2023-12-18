//
//  AcrylicApp.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import SwiftUI
import OSLog

let logger = Logger(subsystem: "dev.anli.macos.Acrylic", category: "Application")

@main
struct AcrylicApp: App {
    @State var authManager = AuthManager()
    
    var body: some Scene {
        #if os(macOS)
        Window("Acrylic", id: "acrylic") {
            ContentView()
                .environmentObject(authManager)
        }
        Window("Debug Assistant", id: "debug-assistant") {
            DebugAssistantView()
        }
        #else
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
        #endif
    }
}

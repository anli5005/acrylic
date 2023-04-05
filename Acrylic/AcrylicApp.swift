//
//  AcrylicApp.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import SwiftUI

@main
struct AcrylicApp: App {
    @State var authManager = AuthManager()
    
    var body: some Scene {
        Window("Acrylic", id: "acrylic") {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

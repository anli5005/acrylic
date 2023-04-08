//
//  ContentView.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import SwiftUI
import FileProvider

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    #if os(macOS)
    @Environment(\.openWindow) var openWindow
    #endif
    
    var body: some View {
        VStack {
            switch authManager.state {
            case .signedOut:
                Button("Sign in") {
                    authManager.signIn()
                }
            case .refreshingAuth:
                ProgressView("Refreshing auth")
            case .signingIn:
                ProgressView("Signing in")
            case .signedIn:
                Text("Signed in")
                #if os(macOS)
                Button("Debug Assistant...") {
                    openWindow(id: "debug-assistant")
                }
                #endif
                Button("Try installing file provider") {
                    NSFileProviderManager.add(Constants.domain) { error in
                        if let error {
                            print("Error: \(error)")
                        }
                    }
                }
                Button("Uninstall file provider") {
                    NSFileProviderManager.remove(Constants.domain, mode: .removeAll) { _, error in
                        if let error {
                            print("Error: \(error)")
                        }
                    }
                }
                Button("Sign out") {
                    authManager.signOut()
                }
            }
        }
        .padding()
        .sheet(isPresented: Binding {
            authManager.state == .signingIn || authManager.state == .refreshingAuth
        } set: { isPresented in
            if isPresented {
                authManager.signIn()
            } else {
                authManager.cancelSigningIn()
            }
        }) {
            SignInView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

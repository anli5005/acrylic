//
//  SignInView.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import SwiftUI
import WebKit

#if os(macOS)
typealias NativeViewRepresentable = NSViewRepresentable
#else
typealias NativeViewRepresentable = UIViewRepresentable
#endif

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @State var baseHost: String = ""
    @State var token: String = ""
    @State var isAskingForToken = false
    
    var tokenURL: String {
        return "https://\(baseHost)/profile/settings"
    }
    
    var body: some View {
        Group {
            if isAskingForToken {
                VStack(spacing: 12) {
                    Text("Paste in Access Token").font(.title).fontWeight(.bold)
                    Text("Acrylic uses an access token to identify itself to Canvas.")
                    Text(.init("To obtain a token, go to [\(tokenURL)](\(tokenURL)#access_tokens), then scroll to **Approved Integrations** and click **New Access Token**."))
                    Text("Once generated, you can copy and paste it here.")
                    
                    Image(systemName: "key.fill")
                        .resizable()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                        .scaledToFit()
                        .frame(maxHeight: 100)
                        .frame(maxHeight: .infinity)
                    
                    TextField("Paste token here...", text: $token).font(.body.monospaced()).frame(maxWidth: .infinity)
                    HStack {
                        Button("Back") {
                            withAnimation {
                                isAskingForToken = false
                            }
                        }.controlSize(.large)
                        Button("Finish") {
                            authManager.finishSigningIn(with: token, on: baseHost)
                        }.controlSize(.large).keyboardShortcut(.defaultAction)
                            .disabled(token.isEmpty)
                    }
                }.frame(maxWidth: .infinity).transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                VStack(spacing: 12) {
                    Text("Enter a Canvas URL").font(.title).fontWeight(.bold)
                    Text("Enter the URL you use to log in to your university's Canvas instance.")
                    
                    Image(systemName: "link.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                        .scaledToFit()
                        .frame(maxHeight: 100)
                        .frame(maxHeight: .infinity)
                    
                    TextField("canvas.myuniversity.edu", text: $baseHost).frame(width: 200).controlSize(.large)
                    HStack {
                        Button("Cancel") {
                            authManager.cancelSigningIn()
                        }.controlSize(.large)
                        Button("Next") {
                            withAnimation {
                                isAskingForToken = true
                            }
                        }.controlSize(.large).keyboardShortcut(.defaultAction)
                            .disabled(baseHost.isEmpty || URL(string: "https://\(baseHost)/test/test?param=hi") == nil)
                    }
                }.frame(maxWidth: .infinity).transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        #if os(macOS)
        .frame(width: 540, height: 360)
        #endif
        .padding(.vertical, 24)
        .padding(.horizontal, 48)
    }
}

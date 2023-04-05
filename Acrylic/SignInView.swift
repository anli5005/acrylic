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
    @State var isOnWebView = false
    
    var body: some View {
        VStack {
            if isOnWebView {
                SignInWebView(baseHost: baseHost).frame(maxWidth: .infinity, minHeight: 400, maxHeight: 400).border(.separator)
                HStack {
                    Button("Back") {
                        isOnWebView = false
                    }.controlSize(.large)
                }
            } else {
                Text("Enter a Canvas URL").font(.title).fontWeight(.bold)
                TextField("canvas.upenn.edu", text: $baseHost).frame(width: 200).controlSize(.large)
                HStack {
                    Button("Cancel") {
                        authManager.cancelSigningIn()
                    }.controlSize(.large)
                    Button("Next") {
                        isOnWebView = true
                    }.controlSize(.large).keyboardShortcut(.defaultAction)
                        .disabled(baseHost.isEmpty || URL(string: "https://\(baseHost)/test/test?param=hi") == nil)
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 600)
        .padding()
    }
}

private struct SignInWebView: NativeViewRepresentable {
    @EnvironmentObject var authManager: AuthManager
    
    var baseHost: String
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: configuration)
        #if os(macOS)
        updateNSView(view, context: context)
        #else
        updateUIView(view, context: context)
        #endif
        view.load(URLRequest(url: URL(string: "https://\(baseHost)")!))
        return view
    }
    
    #if os(macOS)
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.navigationDelegate = context.coordinator
    }
    #else
    func updateUIView(_ nsView: WKWebView, context: Context) {
        nsView.navigationDelegate = context.coordinator
    }
    #endif
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: SignInWebView
        
        init(_ parent: SignInWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if webView.url?.host() == parent.baseHost {
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                    if let cookie = cookies.first(where: { $0.name == "canvas_session" }) {
                        DispatchQueue.main.async {
                            if let self {
                                self.parent.authManager.finishSigningIn(with: cookie.value, on: self.parent.baseHost)
                            }
                        }
                    }
                }
            }
        }
    }
}

//
//  AuthHandlers.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import Foundation
import FileProvider

class AuthManager: ObservableObject {
    enum State {
        case signedOut
        case signingIn
        case signedIn
        case refreshingAuth
    }
    
    @Published var state: State = TokenStorage.retrieveSessionCookie() != nil ? .signedIn : .signedOut
    
    func signIn() {
        if state == .signedIn || state == .refreshingAuth {
            state = .refreshingAuth
        } else {
            state = .signingIn
        }
    }
    
    func finishSigningIn(with cookie: String, on baseHost: String) {
        UserDefaults.group.setValue(baseHost, forKey: "canvasBaseHost")
        TokenStorage.store(sessionCookie: cookie)
        let oldState = state
        state = .signedIn
        
        if oldState == .signingIn {
            NSFileProviderManager.add(Constants.domain) { error in
                if let error {
                    logger.fault("Couldn't add file provider: \(error, privacy: .public)")
                }
            }
        }
    }
    
    func cancelSigningIn() {
        if state == .signingIn {
            state = .signedOut
        } else if state == .refreshingAuth {
            state = .signedIn
        }
    }
    
    func signOut() {
        TokenStorage.clear()
        UserDefaults.group.removeObject(forKey: "canvasBaseHost")
        state = .signedOut
        NSFileProviderManager.remove(Constants.domain, mode: .removeAll) { _, error in
            if let error {
                logger.fault("Couldn't remove file provider: \(error, privacy: .public)")
            }
        }
    }
}

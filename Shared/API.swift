//
//  API.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import Foundation

enum API {
    static var cachedSession: URLSession?
    
    @MainActor static func getSession() -> URLSession {
        guard let baseHost else {
            cachedSession = nil
            return URLSession.shared
        }
        
        print("getSession() called")
        
        if let cachedSession {
            let cookie = HTTPCookie(properties: [
                .name: "canvas_session",
                .value: TokenStorage.retrieveSessionCookie() ?? "",
                .path: "/",
                .domain: baseHost
            ])!
            cachedSession.configuration.httpCookieStorage!.setCookie(cookie)
            return cachedSession
        }
        
        let session = URLSession(configuration: .ephemeral)
        let cookie = HTTPCookie(properties: [
            .name: "canvas_session",
            .value: TokenStorage.retrieveSessionCookie() ?? "",
            .path: "/",
            .domain: baseHost
        ])!
        session.configuration.httpCookieStorage!.setCookie(cookie)
        cachedSession = session
        return session
    }
    
    static var baseHost: String? {
        UserDefaults.group.string(forKey: "canvasBaseHost")
    }
}

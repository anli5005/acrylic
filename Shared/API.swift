//
//  API.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import Foundation

enum API {
    static var cachedSession: URLSession?
    
    static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let token = TokenStorage.retrieveSessionCookie() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    static var baseHost: String? {
        UserDefaults.group.string(forKey: "canvasBaseHost")
    }
}

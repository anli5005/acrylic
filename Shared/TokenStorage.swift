//
//  TokenStorage.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import Foundation
import Security

enum TokenStorage {
    static func retrieveSessionCookie() -> String? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "acryliccanvassession",
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnData as String: true,
        ] as [String : Any] as CFDictionary, &item)
        
        if status == errSecSuccess {
            let data = item as? Data
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }
        
        return nil
        
    }
    
    static func store(sessionCookie: String) {
        guard let data = sessionCookie.data(using: .utf8) else {
            return
        }
        
        let status = SecItemAdd([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "acryliccanvassession",
            kSecAttrLabel as String: "Acrylic Canvas Session",
            kSecUseDataProtectionKeychain as String: true,
            kSecValueData as String: data as CFData
        ] as [String: Any] as CFDictionary, nil)
        
        print("Saved and got status \(status)")
    }
    
    static func clear() {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "acryliccanvassession",
            kSecUseDataProtectionKeychain as String: true
        ] as [String: Any] as CFDictionary)
    }
}

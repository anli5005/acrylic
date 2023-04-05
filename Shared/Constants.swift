//
//  Constants.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import Foundation
import FileProvider

enum Constants {
    #if os(macOS)
    static let groupIdentifier = "9G475R3MEF.dev.anli.macos.AcrylicGroup"
    #else
    static let groupIdentifier = "group.dev.anli.macos.AcrylicGroup"
    #endif
    static let domainIdentifier = NSFileProviderDomainIdentifier("dev.anli.macos.Acrylic.fileproviderdomain")
    static let domain = NSFileProviderDomain(identifier: Constants.domainIdentifier, displayName: "Canvas")
}

extension UserDefaults {
    static var group: UserDefaults {
        UserDefaults(suiteName: Constants.groupIdentifier)!
    }
}

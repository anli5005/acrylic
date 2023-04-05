//
//  Constants.swift
//  Acrylic
//
//  Created by Anthony Li on 4/4/23.
//

import Foundation
import FileProvider

enum Constants {
    static let groupIdentifier = "9G475R3MEF.dev.anli.macos.AcrylicGroup"
    static let domainIdentifier = NSFileProviderDomainIdentifier("dev.anli.macos.Acrylic.fileproviderdomain")
    static let domain = NSFileProviderDomain(identifier: Constants.domainIdentifier, displayName: "Canvas")
}

extension UserDefaults {
    static var group: UserDefaults {
        UserDefaults(suiteName: Constants.groupIdentifier)!
    }
}

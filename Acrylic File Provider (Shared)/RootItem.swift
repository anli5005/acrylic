//
//  FileProviderItem.swift
//  Acrylic File Provider
//
//  Created by Anthony Li on 4/4/23.
//

import FileProvider
import UniformTypeIdentifiers

class RootItem: NSObject, NSFileProviderItem {
    var itemIdentifier: NSFileProviderItemIdentifier {
        .rootContainer
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        .rootContainer
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return [.allowsReading, .allowsContentEnumerating]
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: "a content version".data(using: .utf8)!, metadataVersion: "a metadata version".data(using: .utf8)!)
    }
    
    var filename: String {
        return "Canvas"
    }
    
    var contentType: UTType {
        return .folder
    }
}

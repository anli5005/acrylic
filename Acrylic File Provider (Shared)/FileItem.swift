//
//  FileItem.swift
//  Acrylic File Provider
//
//  Created by Anthony Li on 4/4/23.
//

import FileProvider
import UniformTypeIdentifiers

class FileItem: NSObject, NSFileProviderItem {
    let file: File
    let parentOverride: NSFileProviderItemIdentifier?
    
    init(file: File, overrideParent parentOverride: NSFileProviderItemIdentifier?) {
        self.file = file
        self.parentOverride = parentOverride
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        NSFileProviderItemIdentifier("file-\(file.id)")
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        if let parentOverride {
            return parentOverride
        } else {
            return NSFileProviderItemIdentifier("folder-\(file.folder_id)")
        }
    }
    
    var contentPolicy: NSFileProviderContentPolicy {
        .downloadLazilyAndEvictOnRemoteUpdate
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return .allowsReading
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: "\(file.updated_at.timeIntervalSince1970)".data(using: .utf8)!, metadataVersion: "a metadata version".data(using: .utf8)!)
    }
    
    var filename: String {
        return file.display_name
    }
    
    var contentType: UTType {
        if let contentType = file.content_type {
            return UTType(mimeType: contentType) ?? .data
        } else {
            return .data
        }
    }
    
    var creationDate: Date? {
        return file.created_at
    }
    
    var contentModificationDate: Date? {
        return file.updated_at
    }
    
    var documentSize: NSNumber? {
        return NSNumber(value: UInt(file.size))
    }
}

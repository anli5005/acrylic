//
//  FileProviderItem.swift
//  Acrylic File Provider
//
//  Created by Anthony Li on 4/4/23.
//

import FileProvider
import UniformTypeIdentifiers

class FolderItem: NSObject, NSFileProviderItem {
    let folder: Folder
    
    init(folder: Folder) {
        self.folder = folder
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        NSFileProviderItemIdentifier("folder-\(folder.id)")
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        if folder.full_name == "course files/\(folder.name)" || folder.parent_folder_id == nil {
            return NSFileProviderItemIdentifier("course-\(folder.context_id)")
        } else {
            return NSFileProviderItemIdentifier("folder-\(folder.parent_folder_id!)")
        }
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return .allowsReading
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: "\(folder.updated_at.timeIntervalSince1970)".data(using: .utf8)!, metadataVersion: "a metadata version".data(using: .utf8)!)
    }
    
    var filename: String {
        return folder.name
    }
    
    var contentType: UTType {
        return .folder
    }
    
    var childItemCount: NSNumber? {
        return NSNumber(integerLiteral: folder.files_count + folder.folders_count)
    }
    
    var creationDate: Date? {
        return folder.created_at
    }
    
    var contentModificationDate: Date? {
        return folder.updated_at
    }
}

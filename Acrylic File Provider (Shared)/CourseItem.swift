//
//  FileProviderItem.swift
//  Acrylic File Provider
//
//  Created by Anthony Li on 4/4/23.
//

import FileProvider
import UniformTypeIdentifiers

class CourseItem: NSObject, NSFileProviderItem {
    let course: Course
    
    init(course: Course) {
        self.course = course
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        NSFileProviderItemIdentifier("course-\(course.id)")
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        .rootContainer
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return .allowsReading
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: "a content version".data(using: .utf8)!, metadataVersion: "a metadata version".data(using: .utf8)!)
    }
    
    var filename: String {
        return course.name
    }
    
    var contentType: UTType {
        return .folder
    }
}

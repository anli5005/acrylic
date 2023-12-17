//
//  CourseEnumerator.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import FileProvider

class CourseEnumerator: NSObject, NSFileProviderEnumerator {
    let courseIdentifier: String
    var folderEnumerator: FolderEnumerator?
    
    init(courseIdentifier: String) {
        self.courseIdentifier = courseIdentifier
    }
    
    func invalidate() {}

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        guard let baseHost = API.baseHost else {
            observer.finishEnumeratingWithError(NSFileProviderError(NSFileProviderError.serverUnreachable))
            return
        }
        
        print("CourseEnumerator.enumerateItems()")
        Task {
            do {
                if folderEnumerator == nil {
                    let request = API.request(for: URL(string: "https://\(baseHost)/api/v1/courses/\(courseIdentifier)/folders/root")!)
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let response = response as? HTTPURLResponse, response.statusCode == 403 {
                        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
                    }
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let folder = try decoder.decode(Folder.self, from: data)
                    folderEnumerator = FolderEnumerator(folderIdentifier: String(folder.id), overrideParent: NSFileProviderItemIdentifier("course-\(courseIdentifier)"))
                }
                
                folderEnumerator!.enumerateItems(for: observer, startingAt: page)
            } catch let e {
                observer.finishEnumeratingWithError(e)
            }
        }
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        handleChangeEnumerator(for: observer, from: anchor)
    }

    func currentSyncAnchor() async -> NSFileProviderSyncAnchor? {
        createSyncAnchor()
    }
}

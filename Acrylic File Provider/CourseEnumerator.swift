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
            observer.finishEnumeratingWithError(NSFileProviderError(NSFileProviderError.notAuthenticated))
            return
        }
        
        print("CourseEnumerator.enumerateItems()")
        Task {
            do {
                if folderEnumerator == nil {
                    let session = await API.getSession()
                    var request = URLRequest(url: URL(string: "https://\(baseHost)/api/v1/courses/\(courseIdentifier)/folders/root")!)
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    let (data, _) = try await session.data(for: request)
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

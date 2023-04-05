//
//  RootEnumerator.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import FileProvider

class RootFileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    func invalidate() {}

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        guard let baseHost = API.baseHost else {
            observer.finishEnumeratingWithError(NSFileProviderError(NSFileProviderError.notAuthenticated))
            return
        }

        Task {
            do {
                let session = await API.getSession()
                var request = URLRequest(url: URL(string: "https://\(baseHost)/courses")!)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, _) = try await session.data(for: request)
                let courses = try JSONDecoder().decode([Course].self, from: data)
                observer.didEnumerate(courses.map {
                    CourseItem(course: $0)
                })
                observer.finishEnumerating(upTo: nil)
            } catch {
                observer.finishEnumeratingWithError(NSFileProviderError(.notAuthenticated))
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

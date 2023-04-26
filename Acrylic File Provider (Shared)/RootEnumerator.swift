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
        Task {
            do {
                try await observer.didEnumerate(Course.fetch().map {
                    CourseItem(course: $0)
                })
                observer.finishEnumerating(upTo: nil)
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

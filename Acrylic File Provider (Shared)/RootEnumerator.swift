//
//  RootEnumerator.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import FileProvider

class RootFileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    func invalidate() {}
    
    struct Page: Codable {
        var courses: [Course]
        
        func asPage() throws -> NSFileProviderPage {
            try NSFileProviderPage(PropertyListEncoder().encode(self))
        }
        
        static func from(page: NSFileProviderPage) throws -> Page {
            try PropertyListDecoder().decode(Page.self, from: page.rawValue)
        }
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        Task {
            do {
                if page.rawValue == NSFileProviderPage.initialPageSortedByDate as Data || page.rawValue == NSFileProviderPage.initialPageSortedByName as Data {
                    try await observer.finishEnumerating(upTo: Page(courses: Course.fetch()).asPage())
                } else {
                    var parsedPage = try Page.from(page: page)
                    if let course = parsedPage.courses.last {
                        let (_, response) = try await URLSession.shared.data(for: API.request(for: URL(string: "https://\(API.baseHost ?? "")/api/v1/courses/\(course.id)/folders/root")!))
                        
                        if let response = response as? HTTPURLResponse, response.statusCode != 403 {
                            observer.didEnumerate([CourseItem(course: course)])
                        }
                        
                        parsedPage.courses.removeLast()
                        if parsedPage.courses.isEmpty {
                            observer.finishEnumerating(upTo: nil)
                        } else {
                            try observer.finishEnumerating(upTo: parsedPage.asPage())
                        }
                    } else {
                        observer.finishEnumerating(upTo: nil)
                    }
                }
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

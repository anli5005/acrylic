//
//  WorkingSetEnumerator.swift
//  Acrylic File Provider
//
//  Created by Anthony Li on 4/5/23.
//

import FileProvider

class WorkingSetEnumerator: NSObject, NSFileProviderEnumerator {
    static let perPage = 200
    let rootEnumerator = RootFileProviderEnumerator()
    
    struct Page: Codable {
        let courseIds: [Int]
        let currentIndex: Int
        let coursePage: FolderEnumerator.Page
        let rootFolder: Int?
        
        func asPage() throws -> NSFileProviderPage {
            try NSFileProviderPage(PropertyListEncoder().encode(self))
        }
        
        static func from(page: NSFileProviderPage) throws -> Page {
            try PropertyListDecoder().decode(Page.self, from: page.rawValue)
        }
    }
    
    func invalidate() {}

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        guard let baseHost = API.baseHost else {
            observer.finishEnumeratingWithError(NSFileProviderError(NSFileProviderError.serverUnreachable))
            return
        }
        
        logger.info("WorkingSetEnumerator.enumerateItems()")
        Task {
            do {
                let endpoint: String
                let pageIndex: Int
                if page.rawValue == NSFileProviderPage.initialPageSortedByDate as Data || page.rawValue == NSFileProviderPage.initialPageSortedByName as Data {
                    logger.info("RESTARTING ENUMERATION")
                    do {
                        let courses = try await Course.fetch()
                        observer.didEnumerate(courses.map {
                            CourseItem(course: $0)
                        })
                        try observer.finishEnumerating(upTo: courses.first.map { _ in try Page(courseIds: courses.map(\.id), currentIndex: 0, coursePage: .folderPage(1), rootFolder: nil).asPage() })
                    } catch let e {
                        observer.finishEnumeratingWithError(e)
                    }
                    
                    return
                }
                let parsedPage = try Page.from(page: page)
                switch parsedPage.coursePage {
                    case .filePage(let file):
                        pageIndex = file
                        endpoint = "files"
                    case .folderPage(let folder):
                        pageIndex = folder
                        endpoint = "folders"
                }
                
                logger.info("Now enumerating \(endpoint) page \(pageIndex) from \(parsedPage.currentIndex)")
                
                let request = API.request(for: URL(string: "https://\(baseHost)/api/v1/courses/\(parsedPage.courseIds[parsedPage.currentIndex])/\(endpoint)?per_page=\(Self.perPage)&page=\(pageIndex)")!)
                                
                let result = try? await URLSession.shared.data(for: request)
                let data = result?.0 ?? Data()
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .custom { keys in
                    if keys.last!.stringValue == "content-type" {
                        return ContentTypeCodingKey(stringValue: "content_type")!
                    }
                    
                    return keys.last!
                }
                decoder.dateDecodingStrategy = .iso8601
                
                if endpoint == "folders" {
                    let folders = (try? decoder.decode([Folder].self, from: data)) ?? []
                    observer.didEnumerate(folders.filter {
                        $0.parent_folder_id != nil
                    }.map {
                        FolderItem(folder: $0)
                    })
                    if folders.isEmpty {
                        try observer.finishEnumerating(upTo: Page(courseIds: parsedPage.courseIds, currentIndex: parsedPage.currentIndex, coursePage: .filePage(1), rootFolder: parsedPage.rootFolder).asPage())
                    } else {
                        try observer.finishEnumerating(upTo: Page(courseIds: parsedPage.courseIds, currentIndex: parsedPage.currentIndex, coursePage: .folderPage(pageIndex + 1), rootFolder: folders.first(where: { $0.parent_folder_id == nil })?.id ?? parsedPage.rootFolder).asPage())
                    }
                } else {
                    let files = (try? decoder.decode([File].self, from: data)) ?? []
                    observer.didEnumerate(files.map { file in
                        FileItem(file: file, overrideParent: file.folder_id == parsedPage.rootFolder ? NSFileProviderItemIdentifier("course-\(parsedPage.courseIds[parsedPage.currentIndex])") : nil)
                    })
                    if files.isEmpty {
                        if parsedPage.currentIndex.advanced(by: 1) < parsedPage.courseIds.endIndex {
                            try observer.finishEnumerating(upTo: Page(courseIds: parsedPage.courseIds, currentIndex: parsedPage.currentIndex + 1, coursePage: .folderPage(1), rootFolder: nil).asPage())
                        } else {
                            observer.finishEnumerating(upTo: nil)
                        }
                    } else {
                        try observer.finishEnumerating(upTo: Page(courseIds: parsedPage.courseIds, currentIndex: parsedPage.currentIndex, coursePage: .filePage(pageIndex + 1), rootFolder: parsedPage.rootFolder).asPage())
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

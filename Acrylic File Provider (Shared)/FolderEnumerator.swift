//
//  FolderEnumerator.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import FileProvider

struct ContentTypeCodingKey: CodingKey {
    init?(stringValue: String) {
        if stringValue != "content_type" {
            return nil
        }
    }
    
    init?(intValue: Int) {
        return nil
    }
    
    let stringValue = "content_type"
    let intValue: Int? = nil
}

class FolderEnumerator: NSObject, NSFileProviderEnumerator {
    let folderIdentifier: String
    let overrideParent: NSFileProviderItemIdentifier?
    static let perPage = 50
    
    enum Page: Codable {
        case folderPage(Int)
        case filePage(Int)
        
        func encode() throws -> Data {
            try PropertyListEncoder().encode(self)
        }
        
        init(data: Data) throws {
            self = try PropertyListDecoder().decode(Self.self, from: data)
        }
    }
    
    init(folderIdentifier: String, overrideParent: NSFileProviderItemIdentifier? = nil) {
        self.folderIdentifier = folderIdentifier
        self.overrideParent = overrideParent
    }
    
    func invalidate() {}

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        guard let baseHost = API.baseHost else {
            observer.finishEnumeratingWithError(NSFileProviderError(NSFileProviderError.serverUnreachable))
            return
        }
        
        print("FolderEnumerator.enumerateItems()")
        Task {
            do {
                let endpoint: String
                let pageIndex: Int
                if page.rawValue == NSFileProviderPage.initialPageSortedByDate as Data || page.rawValue == NSFileProviderPage.initialPageSortedByName as Data {
                    endpoint = "folders"
                    pageIndex = 1
                } else {
                    switch try Page(data: page.rawValue) {
                    case .filePage(let file):
                        pageIndex = file
                        endpoint = "files"
                    case .folderPage(let folder):
                        pageIndex = folder
                        endpoint = "folders"
                    }
                }
                
                let request = API.request(for: URL(string: "https://\(baseHost)/api/v1/folders/\(self.folderIdentifier)/\(endpoint)?per_page=\(Self.perPage)&page=\(pageIndex)")!)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let response = response as? HTTPURLResponse, response.statusCode == 403 {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .custom { keys in
                    if keys.last!.stringValue == "content-type" {
                        return ContentTypeCodingKey(stringValue: "content_type")!
                    }
                    
                    return keys.last!
                }
                decoder.dateDecodingStrategy = .iso8601
                
                if endpoint == "folders" {
                    let folders = try decoder.decode([Folder].self, from: data)
                    observer.didEnumerate(folders.map {
                        FolderItem(folder: $0)
                    })
                    if folders.isEmpty {
                        try observer.finishEnumerating(upTo: NSFileProviderPage(Page.filePage(1).encode()))
                    } else {
                        try observer.finishEnumerating(upTo: NSFileProviderPage(Page.folderPage(pageIndex + 1).encode()))
                    }
                } else {
                    let files = try decoder.decode([File].self, from: data)
                    observer.didEnumerate(files.map {
                        FileItem(file: $0, overrideParent: overrideParent)
                    })
                    if files.isEmpty {
                        observer.finishEnumerating(upTo: nil)
                    } else {
                        try observer.finishEnumerating(upTo: NSFileProviderPage(Page.filePage(pageIndex + 1).encode()))
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

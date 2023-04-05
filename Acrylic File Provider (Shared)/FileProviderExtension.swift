//
//  FileProviderExtension.swift
//  Acrylic File Provider
//
//  Created by Anthony Li on 4/4/23.
//

import FileProvider

var didForceReimport = false

class FileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    required init(domain: NSFileProviderDomain) {
        // TODO: The containing application must create a domain using `NSFileProviderManager.add(_:, completionHandler:)`. The system will then launch the application extension process, call `FileProviderExtension.init(domain:)` to instantiate the extension for that domain, and call methods on the instance.
        super.init()
        print("File provider started")
        if !didForceReimport {
            // NSFileProviderManager(for: domain)?.signalEnumerator(for: .rootContainer) { _ in }
            didForceReimport = true
        }
    }
    
    func invalidate() {
        // TODO: cleanup any resources
    }
    
    func item(for identifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) -> Progress {
        // resolve the given identifier to a record in the model
        
        let itemTask = Task<NSFileProviderItem, Error> {
            guard let baseHost = API.baseHost else {
                throw NSFileProviderError(NSFileProviderError.notAuthenticated)
            }
            
            if identifier == NSFileProviderItemIdentifier.rootContainer {
                return RootItem()
            } else if identifier.rawValue.starts(with: "course-") {
                let session = await API.getSession()
                var request = URLRequest(url: URL(string: "https://\(baseHost)/courses")!)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, _) = try await session.data(for: request)
                let courses = try JSONDecoder().decode([Course].self, from: data)
                if let course = courses.first(where: { "course-\($0.id)" == identifier.rawValue }) {
                    return CourseItem(course: course)
                }
            } else if identifier.rawValue.starts(with: "folder-") {
                let session = await API.getSession()
                var request = URLRequest(url: URL(string: "https://\(baseHost)/api/v1/folders/\(identifier.rawValue.split(separator: "-")[1])")!)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, _) = try await session.data(for: request)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let folder = try decoder.decode(Folder.self, from: data)
                return FolderItem(folder: folder)
            } else if identifier.rawValue.starts(with: "file-") {
                let session = await API.getSession()
                var request = URLRequest(url: URL(string: "https://\(baseHost)/api/v1/files/\(identifier.rawValue.split(separator: "-")[1])")!)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, _) = try await session.data(for: request)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let file = try decoder.decode(File.self, from: data)
                
                request = URLRequest(url: URL(string: "https://\(baseHost)/api/v1/folders/\(file.folder_id)")!)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data2, _) = try await session.data(for: request)
                let parent = try decoder.decode(Folder.self, from: data2)
                
                return FileItem(file: file, overrideParent: parent.parent_folder_id == nil ? NSFileProviderItemIdentifier("course-\(parent.context_id)") : nil)
            }
            
            throw NSError.fileProviderErrorForNonExistentItem(withIdentifier: identifier)
        }
        
        Task {
            do {
                completionHandler(try await itemTask.value, nil)
            } catch let e {
                print(identifier)
                completionHandler(nil, e)
            }
        }
        
        return Progress()
    }
    
    func fetchContents(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion?, request: NSFileProviderRequest, completionHandler: @escaping (URL?, NSFileProviderItem?, Error?) -> Void) -> Progress {
        Task {
            guard let baseHost = API.baseHost else {
                completionHandler(nil, nil,  NSFileProviderError(NSFileProviderError.notAuthenticated))
                return
            }
            
            guard itemIdentifier.rawValue.starts(with: "file-") else {
                completionHandler(nil, nil, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
                return
            }
            
            let session = await API.getSession()
            var request = URLRequest(url: URL(string: "https://\(baseHost)/api/v1/files/\(itemIdentifier.rawValue.split(separator: "-")[1])")!)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, _) = try await session.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let file = try decoder.decode(File.self, from: data)
            
            let (url, response) = try await session.download(from: file.url)
            
            if (response as? HTTPURLResponse)?.statusCode != 200 {
                completionHandler(nil, nil, NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError))
            }
            
            request = URLRequest(url: URL(string: "https://\(baseHost)/api/v1/folders/\(file.folder_id)")!)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data2, _) = try await session.data(for: request)
            let parent = try decoder.decode(Folder.self, from: data2)
            
            completionHandler(url, FileItem(file: file, overrideParent: parent.parent_folder_id == nil ? NSFileProviderItemIdentifier("course-\(parent.context_id)") : nil), nil)
        }
        return Progress()
    }
    
    func createItem(basedOn itemTemplate: NSFileProviderItem, fields: NSFileProviderItemFields, contents url: URL?, options: NSFileProviderCreateItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: a new item was created on disk, process the item's creation
        
        completionHandler(itemTemplate, [], false, nil)
        return Progress()
    }
    
    func modifyItem(_ item: NSFileProviderItem, baseVersion version: NSFileProviderItemVersion, changedFields: NSFileProviderItemFields, contents newContents: URL?, options: NSFileProviderModifyItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: an item was modified on disk, process the item's modification
        
        completionHandler(item, [], false, nil)
        return Progress()
    }
    
    func deleteItem(identifier: NSFileProviderItemIdentifier, baseVersion version: NSFileProviderItemVersion, options: NSFileProviderDeleteItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (Error?) -> Void) -> Progress {
        // TODO: an item was deleted on disk, process the item's deletion
        
        completionHandler(NSFileProviderError(NSFileProviderError.deletionRejected))
        return Progress()
    }
    
    func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest) throws -> NSFileProviderEnumerator {
        print("Getting enumerator for \(containerItemIdentifier)")
        if containerItemIdentifier == .rootContainer {
            return RootFileProviderEnumerator()
        } else if containerItemIdentifier.rawValue.starts(with: "course-") {
            return CourseEnumerator(courseIdentifier: String(containerItemIdentifier.rawValue.split(separator: "-")[1]))
        } else if containerItemIdentifier.rawValue.starts(with: "folder-") {
            return FolderEnumerator(folderIdentifier: String(containerItemIdentifier.rawValue.split(separator: "-")[1]))
        } else if containerItemIdentifier == .workingSet {
            return WorkingSetEnumerator()
        }
        
        return EmptyFileProviderEnumerator()
    }
}

func createSyncAnchor() -> NSFileProviderSyncAnchor? {
    try? NSFileProviderSyncAnchor(PropertyListEncoder().encode(Date()))
}

func handleChangeEnumerator(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
    if let date = try? PropertyListDecoder().decode(Date.self, from: anchor.rawValue) {
        if date.timeIntervalSinceNow < -120 {
            observer.finishEnumeratingWithError(NSFileProviderError(.syncAnchorExpired))
            return
        }
    } else if let anchor = createSyncAnchor() {
        observer.finishEnumeratingChanges(upTo: anchor, moreComing: false)
        return
    }
    
    observer.finishEnumeratingChanges(upTo: anchor, moreComing: false)
}

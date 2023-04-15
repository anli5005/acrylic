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
                let request = API.request(for: URL(string: "https://\(baseHost)/api/v1/courses/\(identifier.rawValue.split(separator: "-")[1])")!)
                let (data, _) = try await URLSession.shared.data(for: request)
                let course = try JSONDecoder().decode(Course.self, from: data)
                return CourseItem(course: course)
            } else if identifier.rawValue.starts(with: "folder-") {
                let request = API.request(for: URL(string: "https://\(baseHost)/api/v1/folders/\(identifier.rawValue.split(separator: "-")[1])")!)
                let (data, _) = try await URLSession.shared.data(for: request)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let folder = try decoder.decode(Folder.self, from: data)
                return FolderItem(folder: folder)
            } else if identifier.rawValue.starts(with: "file-") {
                var request = API.request(for: URL(string: "https://\(baseHost)/api/v1/files/\(identifier.rawValue.split(separator: "-")[1])")!)
                let (data, _) = try await URLSession.shared.data(for: request)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let file = try decoder.decode(File.self, from: data)
                
                request = API.request(for: URL(string: "https://\(baseHost)/api/v1/folders/\(file.folder_id)")!)
                let (data2, _) = try await URLSession.shared.data(for: request)
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
        let progress = Progress()
        let task = Task {
            do {
                let (url, item) = try await fetch(for: itemIdentifier, version: requestedVersion, request: request, progress: progress)
                completionHandler(url, item, nil)
            } catch let e {
                if !(e is CancellationError) {
                    completionHandler(nil, nil, e)
                }
            }
        }
        
        progress.cancellationHandler = {
            task.cancel()
            completionHandler(nil, nil, NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
        }
        
        return progress
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

private struct SyncAnchorData: Codable {
    var date = Date()
}

func createSyncAnchor() -> NSFileProviderSyncAnchor? {
    try? NSFileProviderSyncAnchor(PropertyListEncoder().encode(SyncAnchorData()))
}

func handleChangeEnumerator(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
    if let data = try? PropertyListDecoder().decode(SyncAnchorData.self, from: anchor.rawValue) {
        if data.date.timeIntervalSinceNow < -120 {
            observer.finishEnumeratingWithError(NSFileProviderError(.syncAnchorExpired))
            return
        }
    } else if let anchor = createSyncAnchor() {
        observer.finishEnumeratingChanges(upTo: anchor, moreComing: false)
        return
    }
    
    observer.finishEnumeratingChanges(upTo: anchor, moreComing: false)
}

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let progress: Progress
    
    init(progress: Progress) {
        self.progress = progress
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progress.completedUnitCount = totalBytesWritten
    }
}

func fetch(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion?, request: NSFileProviderRequest, progress: Progress) async throws -> (URL, NSFileProviderItem) {
    guard let baseHost = API.baseHost else {
        throw NSFileProviderError(NSFileProviderError.notAuthenticated)
    }
    
    guard itemIdentifier.rawValue.starts(with: "file-") else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
    }
    
    var request = API.request(for: URL(string: "https://\(baseHost)/api/v1/files/\(itemIdentifier.rawValue.split(separator: "-")[1])")!)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let file = try decoder.decode(File.self, from: data)
    
    progress.totalUnitCount = Int64(file.size)
    let delegate = DownloadDelegate(progress: progress)
    
    let (url, response) = try await URLSession.shared.download(for: API.request(for: file.url), delegate: delegate)
    
    if (response as? HTTPURLResponse)?.statusCode != 200 {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
    }
    
    request = API.request(for: URL(string: "https://\(baseHost)/api/v1/folders/\(file.folder_id)")!)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    let (data2, _) = try await URLSession.shared.data(for: request)
    let parent = try decoder.decode(Folder.self, from: data2)
    
    return (url, FileItem(file: file, overrideParent: parent.parent_folder_id == nil ? NSFileProviderItemIdentifier("course-\(parent.context_id)") : nil))
}

//
//  Models.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import Foundation
import FileProvider

struct Course: Decodable {
    var id: Int
    var name: String
    var created_at: Date?
}

struct Folder: Decodable {
    var id: Int
    var context_id: Int
    var full_name: String
    var name: String
    var parent_folder_id: Int?
    var created_at: Date
    var updated_at: Date
    var files_count: Int
    var folders_count: Int
}

struct File: Decodable {
    var id: Int
    var folder_id: Int
    var display_name: String
    var content_type: String?
    var size: Int
    var created_at: Date
    var updated_at: Date
    var url: URL
}

extension Course {
    static func fetch() async throws -> [Course] {
        struct TempCourse: Decodable {
            var id: Int
            var name: String?
            var created_at: Date?
        }
        
        guard let baseHost = API.baseHost else {
            throw NSFileProviderError(NSFileProviderError.serverUnreachable)
        }
        
        var courses = [Course]()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var page = 1
        while true {
            let url = URL(string: "https://\(baseHost)/api/v1/courses?per_page=100&page=\(page)")!
            let (data, _) = try await URLSession.shared.data(for: API.request(for: url))
            do {
                let dataCourses = try decoder.decode([TempCourse].self, from: data)
                courses.append(contentsOf: dataCourses.compactMap {
                    guard let name = $0.name else {
                        return nil
                    }
                    return Course(id: $0.id, name: name, created_at: $0.created_at)
                })
                if dataCourses.count < 1 {
                    break
                }
                page += 1
            } catch {
                // throw NSFileProviderError(NSFileProviderError.notAuthenticated)
                logger.fault("\(error, privacy: .public)")
                break
            }
        }
        
        return courses
    }
}

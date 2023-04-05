//
//  Models.swift
//  Acrylic
//
//  Created by Anthony Li on 4/5/23.
//

import Foundation

struct Course: Decodable {
    var id: Int
    var name: String
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

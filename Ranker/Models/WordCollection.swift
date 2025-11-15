// ranker/Ranker/Models/WordCollection.swift

import Foundation

// Collection of words (favorites, custom lists, etc.)
struct WordCollection: Identifiable {
    let id: Int64
    var name: String
    var description: String
    let createdAt: Date
    var words: [String]  // Word names
    var isSystem: Bool  // System collections (favorites) can't be deleted

    static let favoritesId: Int64 = -1
}

// Collection metadata for database storage
struct CollectionMetadata {
    let id: Int64
    var name: String
    var description: String
    let createdAt: Date
    var isSystem: Bool
}

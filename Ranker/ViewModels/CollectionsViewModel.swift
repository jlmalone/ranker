// ranker/Ranker/ViewModels/CollectionsViewModel.swift

import Foundation
import Combine

class CollectionsViewModel: ObservableObject {
    @Published var collections: [WordCollection] = []
    @Published var selectedCollection: WordCollection?
    @Published var newCollectionName = ""
    @Published var newCollectionDescription = ""
    @Published var showingNewCollectionSheet = false
    @Published var exportData: String?

    private let databaseManager = DatabaseManager()

    init() {
        loadCollections()
    }

    // MARK: - Collections Management

    func loadCollections() {
        collections = databaseManager.fetchAllCollections()
    }

    func createCollection() {
        guard !newCollectionName.isEmpty else { return }

        _ = databaseManager.createCollection(
            name: newCollectionName,
            description: newCollectionDescription
        )

        newCollectionName = ""
        newCollectionDescription = ""
        showingNewCollectionSheet = false

        loadCollections()
    }

    func deleteCollection(_ collection: WordCollection) {
        guard !collection.isSystem else { return } // Don't delete system collections

        databaseManager.deleteCollection(collectionId: collection.id)
        loadCollections()
    }

    func addWordToCollection(word: String, collectionId: Int64) {
        databaseManager.addWordToCollection(word: word, collectionId: collectionId)
        loadCollections()
    }

    func removeWordFromCollection(word: String, collectionId: Int64) {
        databaseManager.removeWordFromCollection(word: word, collectionId: collectionId)
        loadCollections()
    }

    // MARK: - Favorites

    func toggleFavorite(word: String) {
        guard let favorites = databaseManager.getFavoritesCollection() else { return }

        if favorites.words.contains(word.lowercased()) {
            databaseManager.removeWordFromCollection(word: word, collectionId: favorites.id)
        } else {
            databaseManager.addWordToCollection(word: word, collectionId: favorites.id)
        }

        loadCollections()
    }

    func isFavorite(word: String) -> Bool {
        guard let favorites = databaseManager.getFavoritesCollection() else { return false }
        return favorites.words.contains(word.lowercased())
    }

    // MARK: - Import/Export

    func exportCollection(_ collection: WordCollection) {
        let jsonData: [String: Any] = [
            "name": collection.name,
            "description": collection.description,
            "words": collection.words,
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]

        if let jsonString = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
           let string = String(data: jsonString, encoding: .utf8) {
            exportData = string
        }
    }

    func importCollection(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let description = json["description"] as? String,
              let words = json["words"] as? [String] else {
            return
        }

        if let collectionId = databaseManager.createCollection(name: name, description: description) {
            for word in words {
                databaseManager.addWordToCollection(word: word, collectionId: collectionId)
            }
        }

        loadCollections()
    }

    func exportAllCollections() -> String {
        let allCollections = collections.map { collection in
            [
                "id": collection.id,
                "name": collection.name,
                "description": collection.description,
                "words": collection.words,
                "isSystem": collection.isSystem
            ] as [String: Any]
        }

        let exportData: [String: Any] = [
            "collections": allCollections,
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "version": "1.0"
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return ""
    }
}

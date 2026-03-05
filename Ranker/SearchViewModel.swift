import Foundation
import SwiftUI

class SearchViewModel: ObservableObject {
    @Published var searchResults: [Word] = []
    @Published var newWordText: String = ""

    private let databaseManager = DatabaseManager()

    func search(for query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        searchResults = databaseManager.searchWords(query: query)
    }

    func updateWord(_ word: Word) {
        databaseManager.updateWord(word: word)
    }

    func addWord() {
        let cleaned = newWordText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        databaseManager.insertWordFromDump(cleaned, wordSource: "manual")
        newWordText = ""
        // Refresh to show the new word
        search(for: cleaned)
    }
}

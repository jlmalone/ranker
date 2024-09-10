import Foundation
import SwiftUI



class SearchAdbentureViewModel: ObservableObject {
    @Published var searchResults: [Word] = []

    private let databaseManager = DatabaseManager()

    func search(for query: String) {
        print("Searching for: \(query)") // Debugging log to ensure the query is correct
        guard !query.isEmpty else {
            searchResults = [] // If the query is empty, clear results
            return
        }

        searchResults = databaseManager.searchWords(query: query)
        print("Found results: \(searchResults)") // Debugging log to check the results
    }
}

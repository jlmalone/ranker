// ranker/Ranker/ViewModels/SearchViewModel.swift

import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchMode: SearchMode = .pattern
    @Published var searchText = ""
    @Published var searchResults: [String] = []
    @Published var wordAnalysis: WordAnalysis?

    // Advanced filters
    @Published var minLength: String = ""
    @Published var maxLength: String = ""
    @Published var startsWith: String = ""
    @Published var endsWith: String = ""
    @Published var contains: String = ""

    private let searchService = SearchService()

    // MARK: - Search

    func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        switch searchMode {
        case .pattern:
            searchResults = searchService.searchByPattern(searchText)
        case .rhyme:
            searchResults = searchService.findRhymes(for: searchText)
        case .alliteration:
            searchResults = searchService.findAlliterations(startingWith: searchText)
        case .contains:
            searchResults = searchService.searchContaining(searchText)
        case .startsWith:
            searchResults = searchService.searchStartingWith(searchText)
        case .endsWith:
            searchResults = searchService.searchEndingWith(searchText)
        case .length:
            if let length = Int(searchText) {
                searchResults = searchService.searchByLength(length)
            }
        case .advanced:
            performAdvancedSearch()
        }
    }

    func performAdvancedSearch() {
        let min = Int(minLength)
        let max = Int(maxLength)

        searchResults = searchService.searchWithFilters(
            pattern: searchText.isEmpty ? nil : searchText,
            minLength: min,
            maxLength: max,
            startsWith: startsWith.isEmpty ? nil : startsWith,
            endsWith: endsWith.isEmpty ? nil : endsWith,
            contains: contains.isEmpty ? nil : contains
        )
    }

    func analyzeWord(_ word: String) {
        wordAnalysis = searchService.analyzeWord(word)
    }

    func clearFilters() {
        searchText = ""
        minLength = ""
        maxLength = ""
        startsWith = ""
        endsWith = ""
        contains = ""
        searchResults = []
        wordAnalysis = nil
    }
}

enum SearchMode: String, CaseIterable {
    case pattern = "Pattern"
    case rhyme = "Rhyme"
    case alliteration = "Alliteration"
    case contains = "Contains"
    case startsWith = "Starts With"
    case endsWith = "Ends With"
    case length = "Length"
    case advanced = "Advanced"
}

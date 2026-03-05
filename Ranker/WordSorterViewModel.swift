//  ranker/Ranker/WordSorterViewModel.swift

// Manages the words array for the main browser, loads batches, and saves rankings.

import Foundation
import Combine

enum WordFilter: String, CaseIterable {
    case unreviewed = "Unreviewed"
    case myWords = "My Words"
    case hasNotes = "Has Notes"
    case notable = "Notable"
    case reviewed = "Reviewed"
}

class WordSorterViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var dataVersion = 0
    @Published var reviewedCount = 0
    @Published var unreviewedCount = 0
    @Published var currentFilter: WordFilter = .unreviewed
    @Published var filterCount = 0
    @Published var currentPage = 0

    private var databaseManager = DatabaseManager()
    private let batchSize = 40

    init() {
        loadNextBatch()
        refreshCounts()
    }

    func loadNextBatch() {
        // Auto-save any unsaved slider changes before loading new batch
        saveCurrentWords()

        DispatchQueue.main.async {
            switch self.currentFilter {
            case .unreviewed:
                self.words = self.databaseManager.fetchUnreviewedWords(batchSize: self.batchSize)
            case .myWords:
                self.words = self.databaseManager.fetchUserAddedWords(batchSize: self.batchSize, offset: self.currentPage * self.batchSize)
            case .hasNotes:
                self.words = self.databaseManager.fetchWordsWithNotes(batchSize: self.batchSize, offset: self.currentPage * self.batchSize)
            case .notable:
                self.words = self.databaseManager.fetchNotableWords(batchSize: self.batchSize, offset: self.currentPage * self.batchSize)
            case .reviewed:
                self.words = self.databaseManager.fetchReviewedWords(batchSize: self.batchSize, offset: self.currentPage * self.batchSize)
            }
            self.dataVersion += 1
            self.refreshCounts()
        }
    }

    private func saveCurrentWords() {
        for word in words {
            databaseManager.updateWord(word: word)
        }
    }

    func saveRankings() {
        saveCurrentWords()
        if currentFilter == .unreviewed {
            // Random next batch
            currentPage = 0
        } else {
            currentPage += 1
        }
        loadNextBatch()
    }

    func switchFilter(_ filter: WordFilter) {
        currentFilter = filter
        currentPage = 0
        refreshCounts()
        loadNextBatch()
    }

    func refreshCounts() {
        reviewedCount = databaseManager.countReviewedWords()
        unreviewedCount = databaseManager.countUnreviewedWords()

        switch currentFilter {
        case .unreviewed:
            filterCount = unreviewedCount
        case .myWords:
            filterCount = databaseManager.countUserAddedWords()
        case .hasNotes:
            filterCount = databaseManager.countWordsWithNotes()
        case .notable:
            filterCount = databaseManager.countNotableWords()
        case .reviewed:
            filterCount = reviewedCount
        }
    }
}

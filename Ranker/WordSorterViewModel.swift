//  ranker/Ranker/WordSorterViewModel.swift

// Manages the words array for the main browser, loads batches, and saves rankings.

import Foundation
import Combine

class WordSorterViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var dataVersion = 0
    @Published var reviewedCount = 0
    @Published var unreviewedCount = 0

    private var databaseManager = DatabaseManager()

    init() {
        loadNextBatch()
        refreshCounts()
    }

    func loadNextBatch() {
        DispatchQueue.main.async {
            self.words = self.databaseManager.fetchUnreviewedWords(batchSize: 40)
            self.dataVersion += 1
            self.refreshCounts()
        }
    }

    func saveRankings() {
        for word in words {
            databaseManager.updateWord(word: word)
        }
        loadNextBatch()
    }

    func refreshCounts() {
        reviewedCount = databaseManager.countReviewedWords()
        unreviewedCount = databaseManager.countUnreviewedWords()
    }
}

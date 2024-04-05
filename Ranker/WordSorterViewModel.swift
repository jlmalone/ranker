//
//  WordSorterViewModel.swift
//  Ranker
//
//  Created by Joseph Malone on 4/4/24.
//

import Foundation

import Combine


class WordSorterViewModel: ObservableObject {
    @Published var words: [Word] = []
    private var allWords: [Word] = [] // Holds the entire set of words
    private var currentIndex = 0

    init() {
        // Populate `allWords` with an initial set of hardcoded words
        allWords = [
            Word(name: "cat", rank: 0.5),
            Word(name: "dog", rank: 0.5),
            Word(name: "bird", rank: 0.5),
            Word(name: "fish", rank: 0.5),
            Word(name: "elephant", rank: 0.5),
            Word(name: "tiger", rank: 0.5),
            Word(name: "lion", rank: 0.5),
            Word(name: "bear", rank: 0.5),
            Word(name: "shark", rank: 0.5),
            Word(name: "whale", rank: 0.5),
            Word(name: "dolphin", rank: 0.5),
            Word(name: "octopus", rank: 0.5),
            Word(name: "giraffe", rank: 0.5),
            Word(name: "zebra", rank: 0.5),
            Word(name: "rhino", rank: 0.5),
            Word(name: "hippo", rank: 0.5),
            // Add more as needed...
        ]
        loadNextBatch()
    }
    
    func loadNextBatch() {
        guard currentIndex < allWords.count else {
            print("All words have been processed.")
            return
        }
        
        let upperBound = min(currentIndex + 8, allWords.count)
        let nextBatch = allWords[currentIndex..<upperBound]
        words = Array(nextBatch)
        currentIndex += 8
    }
    
    func saveRankings() {
        // Implement saving logic here. For demonstration, this simply prints the rankings.
        for word in words {
            print("\(word.name): \(word.rank)")
        }
        // Assume the save to persistence is here.
        
        loadNextBatch() // Load the next batch after saving.
    }
}



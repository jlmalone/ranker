// ranker/Ranker/Models/Flashcard.swift

import Foundation

// Flashcard for spaced repetition learning
struct Flashcard: Identifiable {
    let id = UUID()
    let word: String
    var lastReviewed: Date?
    var nextReview: Date
    var easeFactor: Double  // SM-2 algorithm: 1.3 to 2.5+
    var interval: Int  // Days until next review
    var repetitions: Int  // Number of successful repetitions

    init(word: String) {
        self.word = word
        self.lastReviewed = nil
        self.nextReview = Date()
        self.easeFactor = 2.5  // Default ease factor
        self.interval = 1  // Start with 1 day
        self.repetitions = 0
    }

    // Update flashcard based on SM-2 algorithm
    mutating func update(quality: Int) {
        // quality: 0-5 (0=complete blackout, 5=perfect recall)
        let q = Double(quality)

        if quality < 3 {
            // Failed recall - reset
            repetitions = 0
            interval = 1
        } else {
            // Successful recall
            repetitions += 1

            if repetitions == 1 {
                interval = 1
            } else if repetitions == 2 {
                interval = 6
            } else {
                interval = Int(Double(interval) * easeFactor)
            }
        }

        // Update ease factor
        easeFactor = max(1.3, easeFactor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)))

        lastReviewed = Date()
        nextReview = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
    }
}

// Quiz result for tracking progress
struct QuizResult: Identifiable {
    let id = UUID()
    let word: String
    let correct: Bool
    let timestamp: Date
    let quizType: QuizType
}

enum QuizType: String {
    case definition
    case synonym
    case antonym
    case spelling
    case usage
}

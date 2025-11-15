// ranker/Ranker/Services/LearningService.swift

import Foundation

// Service for language learning features (flashcards, quizzes, spaced repetition)
class LearningService {
    private let databaseManager = DatabaseManager()
    private let dictionaryService = DictionaryService()

    // MARK: - Flashcards

    func createFlashcard(for word: String) {
        let flashcard = Flashcard(word: word)
        databaseManager.saveFlashcard(flashcard)
    }

    func getDueFlashcards(limit: Int = 20) -> [Flashcard] {
        return databaseManager.fetchDueFlashcards(limit: limit)
    }

    func reviewFlashcard(_ flashcard: inout Flashcard, quality: Int) {
        flashcard.update(quality: quality)
        databaseManager.saveFlashcard(flashcard)
    }

    // MARK: - Quizzes

    func generateDefinitionQuiz(wordCount: Int = 10) -> [QuizQuestion] {
        let words = getRandomReviewedWords(count: wordCount * 2) // Get extra for variety
        var questions: [QuizQuestion] = []

        for word in words.prefix(wordCount) {
            // Fetch definition (this will be async in real implementation)
            questions.append(QuizQuestion(
                word: word,
                type: .definition,
                correctAnswer: word
            ))
        }

        return questions
    }

    func generateSynonymQuiz(wordCount: Int = 10) -> [QuizQuestion] {
        let words = getRandomReviewedWords(count: wordCount)
        return words.map { QuizQuestion(word: $0, type: .synonym, correctAnswer: $0) }
    }

    func generateSpellingQuiz(wordCount: Int = 10) -> [QuizQuestion] {
        let words = getRandomReviewedWords(count: wordCount)
        return words.map { QuizQuestion(word: $0, type: .spelling, correctAnswer: $0) }
    }

    func saveQuizResult(word: String, correct: Bool, quizType: QuizType) {
        let result = QuizResult(word: word, correct: correct, timestamp: Date(), quizType: quizType)
        databaseManager.saveQuizResult(result)

        // Update flashcard if it exists
        if var flashcard = databaseManager.fetchFlashcard(for: word) {
            let quality = correct ? 5 : 0
            flashcard.update(quality: quality)
            databaseManager.saveFlashcard(flashcard)
        }
    }

    func getQuizStatistics() -> QuizStatistics {
        let stats = databaseManager.getQuizStats()
        return QuizStatistics(
            totalQuizzes: stats.total,
            correctAnswers: stats.correct,
            accuracy: stats.accuracy
        )
    }

    // MARK: - Word of the Day

    func getWordOfTheDay() -> String {
        // Use date as seed for consistent daily word
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceEpoch = Int(today.timeIntervalSince1970 / 86400)

        let allWords = databaseManager.getAllWords()
        guard !allWords.isEmpty else { return "word" }

        let index = daysSinceEpoch % allWords.count
        return allWords[index]
    }

    // MARK: - Progress Tracking

    func getProgressStatistics() -> ProgressStatistics {
        let reviewedCount = databaseManager.countReviewedWords()
        let unreviewedCount = databaseManager.countUnreviewedWords()
        let totalWords = reviewedCount + unreviewedCount

        let quizStats = databaseManager.getQuizStats()
        let quizHistory = databaseManager.fetchQuizHistory(limit: 30) // Last 30 quizzes

        let recentAccuracy = calculateRecentAccuracy(from: quizHistory)

        return ProgressStatistics(
            totalWords: totalWords,
            reviewedWords: reviewedCount,
            masteredWords: quizStats.correct,
            totalQuizzes: quizStats.total,
            overallAccuracy: quizStats.accuracy,
            recentAccuracy: recentAccuracy,
            streak: calculateStreak()
        )
    }

    private func calculateRecentAccuracy(from history: [QuizResult]) -> Double {
        guard !history.isEmpty else { return 0.0 }
        let correct = history.filter { $0.correct }.count
        return Double(correct) / Double(history.count)
    }

    private func calculateStreak() -> Int {
        let history = databaseManager.fetchQuizHistory(limit: 100)
        let calendar = Calendar.current

        var streak = 0
        var lastDate: Date?

        for result in history.sorted(by: { $0.timestamp > $1.timestamp }) {
            let resultDate = calendar.startOfDay(for: result.timestamp)

            if let last = lastDate {
                let dayDifference = calendar.dateComponents([.day], from: resultDate, to: last).day ?? 0

                if dayDifference == 0 {
                    // Same day
                    continue
                } else if dayDifference == 1 {
                    // Consecutive day
                    streak += 1
                } else {
                    // Streak broken
                    break
                }
            } else {
                // First result
                let today = calendar.startOfDay(for: Date())
                if resultDate == today || calendar.dateComponents([.day], from: resultDate, to: today).day == 1 {
                    streak = 1
                } else {
                    break
                }
            }

            lastDate = resultDate
        }

        return streak
    }

    private func getRandomReviewedWords(count: Int) -> [String] {
        // Get words that have been reviewed (ranked)
        let allWords = databaseManager.getAllWords()
        return Array(allWords.shuffled().prefix(count))
    }
}

// MARK: - Supporting Types

struct QuizQuestion: Identifiable {
    let id = UUID()
    let word: String
    let type: QuizType
    let correctAnswer: String
    var options: [String] = []
    var userAnswer: String?

    var isCorrect: Bool {
        guard let answer = userAnswer else { return false }
        return answer.lowercased() == correctAnswer.lowercased()
    }
}

struct QuizStatistics {
    let totalQuizzes: Int
    let correctAnswers: Int
    let accuracy: Double

    var percentageString: String {
        String(format: "%.1f%%", accuracy * 100)
    }
}

struct ProgressStatistics {
    let totalWords: Int
    let reviewedWords: Int
    let masteredWords: Int
    let totalQuizzes: Int
    let overallAccuracy: Double
    let recentAccuracy: Double
    let streak: Int

    var reviewedPercentage: Double {
        totalWords > 0 ? Double(reviewedWords) / Double(totalWords) : 0.0
    }

    var masteredPercentage: Double {
        totalWords > 0 ? Double(masteredWords) / Double(totalWords) : 0.0
    }
}

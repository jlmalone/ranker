// ranker/RankerTests/DatabaseManagerTests.swift

import XCTest
@testable import Ranker

class DatabaseManagerTests: XCTestCase {
    var databaseManager: DatabaseManager!

    override func setUp() {
        super.setUp()
        databaseManager = DatabaseManager()
    }

    override func tearDown() {
        databaseManager = nil
        super.tearDown()
    }

    // MARK: - Dictionary Tests (5 tests)

    func testCacheDictionaryEntry() {
        let entry = CachedDictionaryEntry(
            word: "test",
            definition: "a procedure intended to establish the quality",
            partOfSpeech: "noun",
            example: "a spelling test",
            etymology: "From Latin testum",
            phonetic: "/test/",
            audioUrl: "https://example.com/test.mp3",
            synonyms: "exam, trial",
            antonyms: "",
            cachedAt: Date()
        )

        databaseManager.cacheDictionaryEntry(entry)

        let retrieved = databaseManager.getCachedDictionaryEntry(for: "test")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.word, "test")
        XCTAssertEqual(retrieved?.definition, "a procedure intended to establish the quality")
    }

    func testGetCachedDictionaryEntryNotFound() {
        let retrieved = databaseManager.getCachedDictionaryEntry(for: "nonexistentword")
        XCTAssertNil(retrieved)
    }

    func testCacheDictionaryEntryReplaces() {
        let entry1 = CachedDictionaryEntry(
            word: "update",
            definition: "old definition",
            partOfSpeech: "noun",
            example: nil,
            etymology: nil,
            phonetic: nil,
            audioUrl: nil,
            synonyms: "",
            antonyms: "",
            cachedAt: Date()
        )

        databaseManager.cacheDictionaryEntry(entry1)

        let entry2 = CachedDictionaryEntry(
            word: "update",
            definition: "new definition",
            partOfSpeech: "verb",
            example: nil,
            etymology: nil,
            phonetic: nil,
            audioUrl: nil,
            synonyms: "",
            antonyms: "",
            cachedAt: Date()
        )

        databaseManager.cacheDictionaryEntry(entry2)

        let retrieved = databaseManager.getCachedDictionaryEntry(for: "update")
        XCTAssertEqual(retrieved?.definition, "new definition")
        XCTAssertEqual(retrieved?.partOfSpeech, "verb")
    }

    func testDictionaryEntryCaseInsensitive() {
        let entry = CachedDictionaryEntry(
            word: "case",
            definition: "test",
            partOfSpeech: "noun",
            example: nil,
            etymology: nil,
            phonetic: nil,
            audioUrl: nil,
            synonyms: "",
            antonyms: "",
            cachedAt: Date()
        )

        databaseManager.cacheDictionaryEntry(entry)

        let retrieved1 = databaseManager.getCachedDictionaryEntry(for: "case")
        let retrieved2 = databaseManager.getCachedDictionaryEntry(for: "CASE")
        let retrieved3 = databaseManager.getCachedDictionaryEntry(for: "CaSe")

        XCTAssertNotNil(retrieved1)
        XCTAssertNotNil(retrieved2)
        XCTAssertNotNil(retrieved3)
    }

    func testDictionarySynonymsAntonyms() {
        let entry = CachedDictionaryEntry(
            word: "happy",
            definition: "feeling pleasure",
            partOfSpeech: "adjective",
            example: nil,
            etymology: nil,
            phonetic: nil,
            audioUrl: nil,
            synonyms: "joyful, cheerful, glad",
            antonyms: "sad, unhappy, miserable",
            cachedAt: Date()
        )

        databaseManager.cacheDictionaryEntry(entry)

        let retrieved = databaseManager.getCachedDictionaryEntry(for: "happy")
        XCTAssertEqual(retrieved?.synonyms, "joyful, cheerful, glad")
        XCTAssertEqual(retrieved?.antonyms, "sad, unhappy, miserable")
    }

    // MARK: - Collections Tests (10 tests)

    func testCreateCollection() {
        let collectionId = databaseManager.createCollection(name: "Test Collection", description: "A test collection")
        XCTAssertNotNil(collectionId)
    }

    func testFetchAllCollections() {
        _ = databaseManager.createCollection(name: "Collection 1", description: "First")
        _ = databaseManager.createCollection(name: "Collection 2", description: "Second")

        let collections = databaseManager.fetchAllCollections()
        XCTAssertGreaterThanOrEqual(collections.count, 2)
    }

    func testAddWordToCollection() {
        let collectionId = databaseManager.createCollection(name: "Test", description: "Test")!
        databaseManager.addWordToCollection(word: "hello", collectionId: collectionId)

        let words = databaseManager.fetchWordsInCollection(collectionId: collectionId)
        XCTAssertTrue(words.contains("hello"))
    }

    func testRemoveWordFromCollection() {
        let collectionId = databaseManager.createCollection(name: "Test", description: "Test")!
        databaseManager.addWordToCollection(word: "hello", collectionId: collectionId)
        databaseManager.removeWordFromCollection(word: "hello", collectionId: collectionId)

        let words = databaseManager.fetchWordsInCollection(collectionId: collectionId)
        XCTAssertFalse(words.contains("hello"))
    }

    func testDeleteCollection() {
        let collectionId = databaseManager.createCollection(name: "Temp", description: "Temporary")!
        databaseManager.addWordToCollection(word: "test", collectionId: collectionId)

        databaseManager.deleteCollection(collectionId: collectionId)

        let collections = databaseManager.fetchAllCollections()
        XCTAssertFalse(collections.contains(where: { $0.id == collectionId }))
    }

    func testGetFavoritesCollection() {
        let favorites = databaseManager.getFavoritesCollection()
        XCTAssertNotNil(favorites)
        XCTAssertEqual(favorites?.name, "Favorites")
        XCTAssertTrue(favorites?.isSystem ?? false)
    }

    func testAddMultipleWordsToCollection() {
        let collectionId = databaseManager.createCollection(name: "Multi", description: "Test")!

        databaseManager.addWordToCollection(word: "apple", collectionId: collectionId)
        databaseManager.addWordToCollection(word: "banana", collectionId: collectionId)
        databaseManager.addWordToCollection(word: "cherry", collectionId: collectionId)

        let words = databaseManager.fetchWordsInCollection(collectionId: collectionId)
        XCTAssertEqual(words.count, 3)
        XCTAssertTrue(words.contains("apple"))
        XCTAssertTrue(words.contains("banana"))
        XCTAssertTrue(words.contains("cherry"))
    }

    func testCollectionWordCaseInsensitive() {
        let collectionId = databaseManager.createCollection(name: "Case Test", description: "Test")!
        databaseManager.addWordToCollection(word: "UPPER", collectionId: collectionId)

        let words = databaseManager.fetchWordsInCollection(collectionId: collectionId)
        XCTAssertTrue(words.contains("upper"))
    }

    func testDuplicateWordInCollection() {
        let collectionId = databaseManager.createCollection(name: "Dup Test", description: "Test")!

        databaseManager.addWordToCollection(word: "duplicate", collectionId: collectionId)
        databaseManager.addWordToCollection(word: "duplicate", collectionId: collectionId)

        let words = databaseManager.fetchWordsInCollection(collectionId: collectionId)
        XCTAssertEqual(words.filter { $0 == "duplicate" }.count, 1)
    }

    func testEmptyCollection() {
        let collectionId = databaseManager.createCollection(name: "Empty", description: "Test")!
        let words = databaseManager.fetchWordsInCollection(collectionId: collectionId)
        XCTAssertTrue(words.isEmpty)
    }

    // MARK: - Flashcards Tests (8 tests)

    func testSaveFlashcard() {
        let flashcard = Flashcard(word: "memorize")
        databaseManager.saveFlashcard(flashcard)

        let retrieved = databaseManager.fetchFlashcard(for: "memorize")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.word, "memorize")
    }

    func testFlashcardUpdate() {
        var flashcard = Flashcard(word: "learn")
        flashcard.update(quality: 5)

        databaseManager.saveFlashcard(flashcard)

        let retrieved = databaseManager.fetchFlashcard(for: "learn")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.repetitions, 1)
    }

    func testFlashcardEaseFactor() {
        var flashcard = Flashcard(word: "easy")
        XCTAssertEqual(flashcard.easeFactor, 2.5)

        flashcard.update(quality: 5)
        XCTAssertGreaterThan(flashcard.easeFactor, 2.5)
    }

    func testFlashcardInterval() {
        var flashcard = Flashcard(word: "interval")
        flashcard.update(quality: 5)

        XCTAssertGreaterThan(flashcard.interval, 0)
        databaseManager.saveFlashcard(flashcard)

        let retrieved = databaseManager.fetchFlashcard(for: "interval")
        XCTAssertEqual(retrieved?.interval, flashcard.interval)
    }

    func testFetchDueFlashcards() {
        let flashcard1 = Flashcard(word: "due1")
        let flashcard2 = Flashcard(word: "due2")

        databaseManager.saveFlashcard(flashcard1)
        databaseManager.saveFlashcard(flashcard2)

        let dueCards = databaseManager.fetchDueFlashcards(limit: 10)
        XCTAssertGreaterThanOrEqual(dueCards.count, 2)
    }

    func testFlashcardNotFound() {
        let retrieved = databaseManager.fetchFlashcard(for: "nonexistent")
        XCTAssertNil(retrieved)
    }

    func testFlashcardFailedRecall() {
        var flashcard = Flashcard(word: "forget")
        flashcard.update(quality: 5)
        flashcard.update(quality: 5)

        let reps1 = flashcard.repetitions

        flashcard.update(quality: 0) // Failed recall

        XCTAssertEqual(flashcard.repetitions, 0)
        XCTAssertLessThan(flashcard.repetitions, reps1)
    }

    func testFlashcardNextReviewDate() {
        var flashcard = Flashcard(word: "review")
        let now = Date()

        flashcard.update(quality: 4)

        XCTAssertGreaterThan(flashcard.nextReview, now)
    }

    // MARK: - Quiz History Tests (7 tests)

    func testSaveQuizResult() {
        let result = QuizResult(word: "quiz", correct: true, timestamp: Date(), quizType: .definition)
        databaseManager.saveQuizResult(result)

        let history = databaseManager.fetchQuizHistory(limit: 10)
        XCTAssertTrue(history.contains(where: { $0.word == "quiz" }))
    }

    func testFetchQuizHistory() {
        let result1 = QuizResult(word: "test1", correct: true, timestamp: Date(), quizType: .definition)
        let result2 = QuizResult(word: "test2", correct: false, timestamp: Date(), quizType: .synonym)

        databaseManager.saveQuizResult(result1)
        databaseManager.saveQuizResult(result2)

        let history = databaseManager.fetchQuizHistory(limit: 10)
        XCTAssertGreaterThanOrEqual(history.count, 2)
    }

    func testQuizStats() {
        let result1 = QuizResult(word: "q1", correct: true, timestamp: Date(), quizType: .definition)
        let result2 = QuizResult(word: "q2", correct: true, timestamp: Date(), quizType: .definition)
        let result3 = QuizResult(word: "q3", correct: false, timestamp: Date(), quizType: .definition)

        databaseManager.saveQuizResult(result1)
        databaseManager.saveQuizResult(result2)
        databaseManager.saveQuizResult(result3)

        let stats = databaseManager.getQuizStats()
        XCTAssertGreaterThanOrEqual(stats.total, 3)
        XCTAssertGreaterThan(stats.accuracy, 0.0)
    }

    func testQuizAccuracy() {
        // Clear previous results by creating new words
        let uniqueId = UUID().uuidString.prefix(8)
        let result1 = QuizResult(word: "acc1_\(uniqueId)", correct: true, timestamp: Date(), quizType: .definition)
        let result2 = QuizResult(word: "acc2_\(uniqueId)", correct: false, timestamp: Date(), quizType: .definition)

        databaseManager.saveQuizResult(result1)
        databaseManager.saveQuizResult(result2)

        let stats = databaseManager.getQuizStats()
        XCTAssertGreaterThan(stats.total, 0)
    }

    func testQuizTypes() {
        let types: [QuizType] = [.definition, .synonym, .antonym, .spelling, .usage]

        for (index, type) in types.enumerated() {
            let result = QuizResult(word: "type\(index)", correct: true, timestamp: Date(), quizType: type)
            databaseManager.saveQuizResult(result)
        }

        let history = databaseManager.fetchQuizHistory(limit: 10)
        XCTAssertGreaterThanOrEqual(history.count, 5)
    }

    func testQuizHistoryOrdering() {
        let old = QuizResult(word: "old", correct: true, timestamp: Date().addingTimeInterval(-1000), quizType: .definition)
        let new = QuizResult(word: "new", correct: true, timestamp: Date(), quizType: .definition)

        databaseManager.saveQuizResult(old)
        databaseManager.saveQuizResult(new)

        let history = databaseManager.fetchQuizHistory(limit: 10)
        if let first = history.first {
            // Most recent should be first
            XCTAssertEqual(first.word, "new")
        }
    }

    func testQuizCorrectness() {
        let correct = QuizResult(word: "right", correct: true, timestamp: Date(), quizType: .definition)
        let incorrect = QuizResult(word: "wrong", correct: false, timestamp: Date(), quizType: .definition)

        databaseManager.saveQuizResult(correct)
        databaseManager.saveQuizResult(incorrect)

        let history = databaseManager.fetchQuizHistory(limit: 10)
        XCTAssertTrue(history.contains(where: { $0.word == "right" && $0.correct }))
        XCTAssertTrue(history.contains(where: { $0.word == "wrong" && !$0.correct }))
    }

    // MARK: - Game Scores Tests (5 tests)

    func testSaveGameScore() {
        let score = GameScore(gameType: .anagramSolver, score: 100, timestamp: Date(), details: "Test game")
        databaseManager.saveGameScore(score)

        let scores = databaseManager.fetchHighScores(gameType: .anagramSolver, limit: 10)
        XCTAssertTrue(scores.contains(where: { $0.score == 100 }))
    }

    func testFetchHighScores() {
        let score1 = GameScore(gameType: .boggleSolver, score: 500, timestamp: Date(), details: "Game 1")
        let score2 = GameScore(gameType: .boggleSolver, score: 300, timestamp: Date(), details: "Game 2")
        let score3 = GameScore(gameType: .boggleSolver, score: 700, timestamp: Date(), details: "Game 3")

        databaseManager.saveGameScore(score1)
        databaseManager.saveGameScore(score2)
        databaseManager.saveGameScore(score3)

        let highScores = databaseManager.fetchHighScores(gameType: .boggleSolver, limit: 10)
        XCTAssertGreaterThanOrEqual(highScores.count, 3)

        // Should be ordered by score descending
        if highScores.count >= 2 {
            XCTAssertGreaterThanOrEqual(highScores[0].score, highScores[1].score)
        }
    }

    func testGameScoresByType() {
        let anagram = GameScore(gameType: .anagramSolver, score: 100, timestamp: Date(), details: "")
        let scrabble = GameScore(gameType: .scrabbleScorer, score: 200, timestamp: Date(), details: "")

        databaseManager.saveGameScore(anagram)
        databaseManager.saveGameScore(scrabble)

        let anagramScores = databaseManager.fetchHighScores(gameType: .anagramSolver, limit: 10)
        let scrabbleScores = databaseManager.fetchHighScores(gameType: .scrabbleScorer, limit: 10)

        XCTAssertTrue(anagramScores.contains(where: { $0.gameType == .anagramSolver }))
        XCTAssertTrue(scrabbleScores.contains(where: { $0.gameType == .scrabbleScorer }))
    }

    func testGameScoreLimit() {
        for i in 1...15 {
            let score = GameScore(gameType: .wordScramble, score: i * 10, timestamp: Date(), details: "")
            databaseManager.saveGameScore(score)
        }

        let scores = databaseManager.fetchHighScores(gameType: .wordScramble, limit: 10)
        XCTAssertLessThanOrEqual(scores.count, 10)
    }

    func testAllGameTypes() {
        let types = GameType.allCases
        for (index, type) in types.enumerated() {
            let score = GameScore(gameType: type, score: index * 100, timestamp: Date(), details: "")
            databaseManager.saveGameScore(score)
        }

        for type in types {
            let scores = databaseManager.fetchHighScores(gameType: type, limit: 10)
            XCTAssertTrue(scores.contains(where: { $0.gameType == type }))
        }
    }

    // MARK: - Search Tests (10 tests)

    func testSearchWordsByPattern() {
        let results = databaseManager.searchWords(pattern: "c_t")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.contains(where: { $0.count == 3 && $0.hasPrefix("c") && $0.hasSuffix("t") }))
    }

    func testSearchWordsByLength() {
        let results = databaseManager.searchWordsByLength(length: 3)
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.count == 3 })
    }

    func testSearchWordsContaining() {
        let results = databaseManager.searchWordsContaining(substring: "at")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.contains("at") })
    }

    func testSearchWordsStartingWith() {
        let results = databaseManager.searchWordsStartingWith(prefix: "ba")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("ba") })
    }

    func testSearchWordsEndingWith() {
        let results = databaseManager.searchWordsEndingWith(suffix: "at")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasSuffix("at") })
    }

    func testSearchCaseInsensitive() {
        let results1 = databaseManager.searchWordsStartingWith(prefix: "ab")
        let results2 = databaseManager.searchWordsStartingWith(prefix: "AB")
        XCTAssertEqual(results1.count, results2.count)
    }

    func testSearchLimit() {
        let results = databaseManager.searchWordsByLength(length: 3)
        XCTAssertLessThanOrEqual(results.count, 100)
    }

    func testSearchEmptyResults() {
        let results = databaseManager.searchWordsContaining(substring: "zzzqqq")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchWildcard() {
        let results = databaseManager.searchWords(pattern: "b%")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("b") })
    }

    func testGetAllWords() {
        let allWords = databaseManager.getAllWords()
        XCTAssertGreaterThan(allWords.count, 0)
    }

    // MARK: - Performance Tests (5 tests)

    func testPerformanceDatabaseQuery() {
        measure {
            _ = databaseManager.fetchUnreviewedWords(batchSize: 20)
        }
    }

    func testPerformanceSearchWords() {
        measure {
            _ = databaseManager.searchWordsStartingWith(prefix: "a")
        }
    }

    func testPerformanceCollectionFetch() {
        measure {
            _ = databaseManager.fetchAllCollections()
        }
    }

    func testPerformanceFlashcardFetch() {
        measure {
            _ = databaseManager.fetchDueFlashcards(limit: 20)
        }
    }

    func testPerformanceQuizStats() {
        measure {
            _ = databaseManager.getQuizStats()
        }
    }
}

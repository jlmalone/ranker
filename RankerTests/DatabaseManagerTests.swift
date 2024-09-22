import Foundation

import XCTest
@testable import Ranker

class DatabaseManagerTests: XCTestCase {
    var databaseManager: DatabaseManager!

    override func setUp() {
        super.setUp()
        if ProcessInfo.processInfo.environment["SIMULATOR_ONLY"] != nil {
            // Proceed with test setup
        } else {
            fatalError("Tests should only be run on the simulator.")
        }
        databaseManager = DatabaseManager()
    }

    override func tearDown() {
        // Clean up after each test
        databaseManager = nil
        super.tearDown()
    }

    func testInsertAndFetchUnreviewedWords() {
        // Test that words can be fetched correctly
        let unreviewedWords = databaseManager.fetchUnreviewedWords(batchSize: 10)
        XCTAssertNotNil(unreviewedWords)
        XCTAssertLessThanOrEqual(unreviewedWords.count, 10)
    }

    func testUpdateWord() {
        // Fetch a word to update
        guard let word = databaseManager.fetchUnreviewedWords(batchSize: 1).first else {
            XCTFail("No unreviewed words available.")
            return
        }

        var updatedWord = word
        updatedWord.rank = 0.9
        updatedWord.isNotable = true

        databaseManager.updateWord(word: updatedWord)

        // Verify the update
        let fetchedWord = databaseManager.searchWords(query: word.name).first
        XCTAssertEqual(fetchedWord?.rank, 0.9)
        XCTAssertEqual(fetchedWord?.isNotable, true)
    }

    func testCountReviewedWords() {
        let initialCount = databaseManager.countReviewedWords()

        // Update a word to be reviewed
        guard let word = databaseManager.fetchUnreviewedWords(batchSize: 1).first else {
            XCTFail("No unreviewed words available.")
            return
        }
        var updatedWord = word
        updatedWord.rank = 0.7  // Any value other than 0.5
        databaseManager.updateWord(word: updatedWord)

        let newCount = databaseManager.countReviewedWords()
        XCTAssertEqual(newCount, initialCount + 1)
    }

    func testSearchWords() {
        let results = databaseManager.searchWords(query: "alpha")
        XCTAssertTrue(results.contains(where: { $0.name == "alpha" }))
    }
}

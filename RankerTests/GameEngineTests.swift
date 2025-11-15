// ranker/RankerTests/GameEngineTests.swift

import XCTest
@testable import Ranker

class GameEngineTests: XCTestCase {
    var gameEngine: GameEngine!

    override func setUp() {
        super.setUp()
        gameEngine = GameEngine()
    }

    override func tearDown() {
        gameEngine = nil
        super.tearDown()
    }

    // MARK: - Scrabble Scorer Tests (5 tests)

    func testScrabbleScoreSimple() {
        let score = ScrabbleScorer.score(word: "cat")
        XCTAssertEqual(score, 5) // c=3, a=1, t=1
    }

    func testScrabbleScoreHighValue() {
        let score = ScrabbleScorer.score(word: "quiz")
        XCTAssertEqual(score, 22) // q=10, u=1, i=1, z=10
    }

    func testScrabbleScoreEmpty() {
        let score = ScrabbleScorer.score(word: "")
        XCTAssertEqual(score, 0)
    }

    func testScrabbleScoreCaseInsensitive() {
        let score1 = ScrabbleScorer.score(word: "word")
        let score2 = ScrabbleScorer.score(word: "WORD")
        XCTAssertEqual(score1, score2)
    }

    func testScrabbleScoreAllLetters() {
        let score = ScrabbleScorer.score(word: "abcdefghijklmnopqrstuvwxyz")
        XCTAssertGreaterThan(score, 0)
    }

    // MARK: - Crossword Pattern Tests (5 tests)

    func testCrosswordPatternExactMatch() {
        let pattern = CrosswordPattern(pattern: "cat")
        XCTAssertTrue(pattern.matches("cat"))
        XCTAssertFalse(pattern.matches("dog"))
    }

    func testCrosswordPatternWildcard() {
        let pattern = CrosswordPattern(pattern: "c?t")
        XCTAssertTrue(pattern.matches("cat"))
        XCTAssertTrue(pattern.matches("cot"))
        XCTAssertTrue(pattern.matches("cut"))
        XCTAssertFalse(pattern.matches("cart"))
    }

    func testCrosswordPatternLength() {
        let pattern = CrosswordPattern(pattern: "???")
        XCTAssertEqual(pattern.length, 3)
        XCTAssertTrue(pattern.matches("cat"))
        XCTAssertFalse(pattern.matches("cart"))
    }

    func testCrosswordPatternMultipleWildcards() {
        let pattern = CrosswordPattern(pattern: "?a?")
        XCTAssertTrue(pattern.matches("cat"))
        XCTAssertTrue(pattern.matches("bat"))
        XCTAssertFalse(pattern.matches("dog"))
    }

    func testCrosswordPatternMixedWildcards() {
        let pattern = CrosswordPattern(pattern: "c??e")
        XCTAssertTrue(pattern.matches("cake"))
        XCTAssertTrue(pattern.matches("care"))
        XCTAssertFalse(pattern.matches("cat"))
    }

    // MARK: - Word Scramble Tests (3 tests)

    func testGenerateScramble() {
        let original = "hello"
        let scrambled = gameEngine.generateScramble(word: original)

        XCTAssertEqual(scrambled.count, original.count)
        // Check all characters are present
        XCTAssertEqual(Set(scrambled), Set(original))
    }

    func testValidateScrambleCorrect() {
        let isValid = gameEngine.validateScrambleAnswer(scrambled: "lehol", original: "hello", answer: "hello")
        XCTAssertTrue(isValid)
    }

    func testValidateScrambleIncorrect() {
        let isValid = gameEngine.validateScrambleAnswer(scrambled: "lehol", original: "hello", answer: "world")
        XCTAssertFalse(isValid)
    }

    // MARK: - Boggle Board Tests (5 tests)

    func testBoggleBoardCreation() {
        let board = BoggleBoard(size: 4)
        XCTAssertEqual(board.grid.count, 4)
        XCTAssertEqual(board.grid[0].count, 4)
    }

    func testBoggleBoardCustom() {
        let grid: [[Character]] = [
            ["a", "b"],
            ["c", "d"]
        ]
        let board = BoggleBoard(grid: grid)
        XCTAssertEqual(board.size, 2)
        XCTAssertEqual(board.grid[0][0], "a")
    }

    func testBoggleSolverFindsWords() {
        let grid: [[Character]] = [
            ["c", "a", "t", "s"],
            ["o", "a", "r", "e"],
            ["d", "o", "g", "s"],
            ["b", "e", "d", "s"]
        ]
        let board = BoggleBoard(grid: grid)
        let results = gameEngine.solveBoggle(board: board, minLength: 3)

        // Should find at least some 3-letter words
        XCTAssertGreaterThan(results.count, 0)
    }

    func testBoggleSolverMinLength() {
        let grid: [[Character]] = [
            ["a", "b"],
            ["c", "d"]
        ]
        let board = BoggleBoard(grid: grid)
        let results = gameEngine.solveBoggle(board: board, minLength: 5)

        // Unlikely to find 5-letter words in 2x2 board
        XCTAssertEqual(results.count, 0)
    }

    func testBoggleSolverScoring() {
        let grid: [[Character]] = [
            ["c", "a", "t", "s"],
            ["o", "a", "r", "e"],
            ["d", "o", "g", "s"],
            ["b", "e", "d", "s"]
        ]
        let board = BoggleBoard(grid: grid)
        let results = gameEngine.solveBoggle(board: board, minLength: 3)

        // All results should have scores
        XCTAssertTrue(results.allSatisfy { $0.score > 0 })
    }

    // MARK: - Random Word Tests (2 tests)

    func testGetRandomWords() {
        let words = gameEngine.getRandomWords(count: 10)
        XCTAssertEqual(words.count, 10)
    }

    func testGetRandomWordsUnique() {
        let words = gameEngine.getRandomWords(count: 5)
        let uniqueWords = Set(words)
        // Most words should be unique (allowing for small chance of duplicates)
        XCTAssertGreaterThanOrEqual(uniqueWords.count, 3)
    }
}

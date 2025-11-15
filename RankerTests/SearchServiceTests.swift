// ranker/RankerTests/SearchServiceTests.swift

import XCTest
@testable import Ranker

class SearchServiceTests: XCTestCase {
    var searchService: SearchService!

    override func setUp() {
        super.setUp()
        searchService = SearchService()
    }

    override func tearDown() {
        searchService = nil
        super.tearDown()
    }

    // MARK: - Pattern Search Tests (3 tests)

    func testSearchByPattern() {
        let results = searchService.searchByPattern("c?t")
        XCTAssertGreaterThan(results.count, 0)
    }

    func testSearchByPatternNoMatch() {
        let results = searchService.searchByPattern("zzqqxx")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchByPatternWildcard() {
        let results = searchService.searchByPattern("a*")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("a") })
    }

    // MARK: - Length Filter Tests (2 tests)

    func testSearchByLength() {
        let results = searchService.searchByLength(3)
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.count == 3 })
    }

    func testSearchByLengthZero() {
        let results = searchService.searchByLength(0)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Contains/Starts/Ends Tests (6 tests)

    func testSearchContaining() {
        let results = searchService.searchContaining("at")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.contains("at") })
    }

    func testSearchStartingWith() {
        let results = searchService.searchStartingWith("ca")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("ca") })
    }

    func testSearchEndingWith() {
        let results = searchService.searchEndingWith("at")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasSuffix("at") })
    }

    func testSearchContainingCaseInsensitive() {
        let results1 = searchService.searchContaining("AT")
        let results2 = searchService.searchContaining("at")
        XCTAssertEqual(results1.count, results2.count)
    }

    func testSearchStartingWithEmpty() {
        let results = searchService.searchStartingWith("")
        // Empty prefix should match everything (up to limit)
        XCTAssertGreaterThan(results.count, 0)
    }

    func testSearchEndingWithSingleChar() {
        let results = searchService.searchEndingWith("t")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasSuffix("t") })
    }

    // MARK: - Rhyme Finder Tests (4 tests)

    func testFindRhymes() {
        let rhymes = searchService.findRhymes(for: "cat")
        XCTAssertGreaterThan(rhymes.count, 0)
        // Should find words ending in "at"
        XCTAssertTrue(rhymes.contains(where: { $0.hasSuffix("at") }))
    }

    func testFindRhymesExcludesOriginal() {
        let rhymes = searchService.findRhymes(for: "cat")
        XCTAssertFalse(rhymes.contains("cat"))
    }

    func testFindRhymesShortWord() {
        let rhymes = searchService.findRhymes(for: "at")
        XCTAssertGreaterThan(rhymes.count, 0)
    }

    func testFindRhymesLimit() {
        let rhymes = searchService.findRhymes(for: "cat")
        XCTAssertLessThanOrEqual(rhymes.count, 50)
    }

    // MARK: - Alliteration Tests (2 tests)

    func testFindAlliterations() {
        let results = searchService.findAlliterations(startingWith: "b")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("b") })
    }

    func testFindAlliterationsCaseInsensitive() {
        let results1 = searchService.findAlliterations(startingWith: "B")
        let results2 = searchService.findAlliterations(startingWith: "b")
        XCTAssertEqual(results1.count, results2.count)
    }

    // MARK: - Advanced Filter Tests (5 tests)

    func testSearchWithFiltersPattern() {
        let results = searchService.searchWithFilters(pattern: "c?t")
        XCTAssertGreaterThan(results.count, 0)
    }

    func testSearchWithFiltersLength() {
        let results = searchService.searchWithFilters(minLength: 3, maxLength: 5)
        XCTAssertTrue(results.allSatisfy { $0.count >= 3 && $0.count <= 5 })
    }

    func testSearchWithFiltersStartsWith() {
        let results = searchService.searchWithFilters(startsWith: "ca")
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("ca") })
    }

    func testSearchWithFiltersEndsWith() {
        let results = searchService.searchWithFilters(endsWith: "at")
        XCTAssertTrue(results.allSatisfy { $0.hasSuffix("at") })
    }

    func testSearchWithFiltersCombined() {
        let results = searchService.searchWithFilters(
            minLength: 3,
            maxLength: 3,
            startsWith: "c",
            endsWith: "t"
        )
        XCTAssertTrue(results.allSatisfy { $0.count == 3 && $0.hasPrefix("c") && $0.hasSuffix("t") })
    }

    // MARK: - Word Analysis Tests (8 tests)

    func testAnalyzeWordBasic() {
        let analysis = searchService.analyzeWord("hello")
        XCTAssertEqual(analysis.word, "hello")
        XCTAssertEqual(analysis.length, 5)
    }

    func testAnalyzeWordVowels() {
        let analysis = searchService.analyzeWord("aeiou")
        XCTAssertEqual(analysis.vowelCount, 5)
        XCTAssertEqual(analysis.consonantCount, 0)
    }

    func testAnalyzeWordConsonants() {
        let analysis = searchService.analyzeWord("bcdfg")
        XCTAssertEqual(analysis.consonantCount, 5)
        XCTAssertEqual(analysis.vowelCount, 0)
    }

    func testAnalyzeWordUniqueLetters() {
        let analysis = searchService.analyzeWord("aabbcc")
        XCTAssertEqual(analysis.uniqueLetters, 3)
    }

    func testAnalyzeWordScrabbleScore() {
        let analysis = searchService.analyzeWord("quiz")
        XCTAssertGreaterThan(analysis.scrabbleScore, 0)
    }

    func testAnalyzeWordPalindrome() {
        let analysis1 = searchService.analyzeWord("racecar")
        XCTAssertTrue(analysis1.isPalindrome)

        let analysis2 = searchService.analyzeWord("hello")
        XCTAssertFalse(analysis2.isPalindrome)
    }

    func testAnalyzeWordLetterFrequency() {
        let analysis = searchService.analyzeWord("hello")
        XCTAssertEqual(analysis.letterFrequency["l"], 2)
        XCTAssertEqual(analysis.letterFrequency["h"], 1)
    }

    func testAnalyzeWordCaseInsensitive() {
        let analysis1 = searchService.analyzeWord("HELLO")
        let analysis2 = searchService.analyzeWord("hello")
        XCTAssertEqual(analysis1.word, analysis2.word)
    }
}

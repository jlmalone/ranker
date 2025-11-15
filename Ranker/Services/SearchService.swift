// ranker/Ranker/Services/SearchService.swift

import Foundation

// Service for advanced word search features
class SearchService {
    private let databaseManager = DatabaseManager()

    // MARK: - Pattern Search

    func searchByPattern(_ pattern: String) -> [String] {
        return databaseManager.searchWords(pattern: pattern)
    }

    // MARK: - Length Filter

    func searchByLength(_ length: Int) -> [String] {
        return databaseManager.searchWordsByLength(length: length)
    }

    // MARK: - Contains/Starts/Ends

    func searchContaining(_ substring: String) -> [String] {
        return databaseManager.searchWordsContaining(substring: substring)
    }

    func searchStartingWith(_ prefix: String) -> [String] {
        return databaseManager.searchWordsStartingWith(prefix: prefix)
    }

    func searchEndingWith(_ suffix: String) -> [String] {
        return databaseManager.searchWordsEndingWith(suffix: suffix)
    }

    // MARK: - Rhyme Finder

    func findRhymes(for word: String) -> [String] {
        let normalized = word.lowercased()
        guard normalized.count >= 2 else { return [] }

        // Find words ending with the same 2-3 letters
        let rhymeEnding = String(normalized.suffix(min(3, normalized.count)))
        var results = databaseManager.searchWordsEndingWith(suffix: rhymeEnding)

        // Remove the original word
        results.removeAll { $0 == normalized }

        // Sort by similarity
        return results.sorted { word1, word2 in
            let score1 = rhymeScore(word1, original: normalized)
            let score2 = rhymeScore(word2, original: normalized)
            return score1 > score2
        }.prefix(50).map { $0 }
    }

    private func rhymeScore(_ word: String, original: String) -> Int {
        let minLength = min(word.count, original.count)
        var score = 0

        // Count matching characters from the end
        for i in 1...minLength {
            let wordChar = word[word.index(word.endIndex, offsetBy: -i)]
            let origChar = original[original.index(original.endIndex, offsetBy: -i)]

            if wordChar == origChar {
                score += 1
            } else {
                break
            }
        }

        return score
    }

    // MARK: - Alliteration Finder

    func findAlliterations(startingWith letter: String) -> [String] {
        guard let firstChar = letter.lowercased().first, firstChar.isLetter else {
            return []
        }

        return databaseManager.searchWordsStartingWith(prefix: String(firstChar))
    }

    // MARK: - Advanced Filters

    func searchWithFilters(
        pattern: String? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        startsWith: String? = nil,
        endsWith: String? = nil,
        contains: String? = nil
    ) -> [String] {
        var results = databaseManager.getAllWords()

        // Apply pattern filter
        if let pattern = pattern, !pattern.isEmpty {
            let patternResults = searchByPattern(pattern)
            results = results.filter { patternResults.contains($0) }
        }

        // Apply length filters
        if let min = minLength {
            results = results.filter { $0.count >= min }
        }
        if let max = maxLength {
            results = results.filter { $0.count <= max }
        }

        // Apply starts with filter
        if let prefix = startsWith, !prefix.isEmpty {
            results = results.filter { $0.hasPrefix(prefix.lowercased()) }
        }

        // Apply ends with filter
        if let suffix = endsWith, !suffix.isEmpty {
            results = results.filter { $0.hasSuffix(suffix.lowercased()) }
        }

        // Apply contains filter
        if let substring = contains, !substring.isEmpty {
            results = results.filter { $0.contains(substring.lowercased()) }
        }

        return Array(results.prefix(100))
    }

    // MARK: - Word Analysis

    func analyzeWord(_ word: String) -> WordAnalysis {
        let normalized = word.lowercased()

        return WordAnalysis(
            word: normalized,
            length: normalized.count,
            vowelCount: countVowels(in: normalized),
            consonantCount: countConsonants(in: normalized),
            uniqueLetters: Set(normalized).count,
            scrabbleScore: ScrabbleScorer.score(word: normalized),
            isPalindrome: isPalindrome(normalized),
            letterFrequency: getLetterFrequency(in: normalized)
        )
    }

    private func countVowels(in word: String) -> Int {
        let vowels = Set("aeiou")
        return word.filter { vowels.contains($0) }.count
    }

    private func countConsonants(in word: String) -> Int {
        let consonants = Set("bcdfghjklmnpqrstvwxyz")
        return word.filter { consonants.contains($0) }.count
    }

    private func isPalindrome(_ word: String) -> Bool {
        return word == String(word.reversed())
    }

    private func getLetterFrequency(in word: String) -> [Character: Int] {
        var frequency: [Character: Int] = [:]
        for char in word {
            frequency[char, default: 0] += 1
        }
        return frequency
    }
}

// MARK: - Supporting Types

struct WordAnalysis {
    let word: String
    let length: Int
    let vowelCount: Int
    let consonantCount: Int
    let uniqueLetters: Int
    let scrabbleScore: Int
    let isPalindrome: Bool
    let letterFrequency: [Character: Int]

    var analysis: String {
        """
        Word: \(word)
        Length: \(length) letters
        Vowels: \(vowelCount), Consonants: \(consonantCount)
        Unique letters: \(uniqueLetters)
        Scrabble score: \(scrabbleScore)
        Palindrome: \(isPalindrome ? "Yes" : "No")
        """
    }
}

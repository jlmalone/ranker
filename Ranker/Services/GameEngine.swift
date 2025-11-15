// ranker/Ranker/Services/GameEngine.swift

import Foundation

// Service for word game logic
class GameEngine {
    private let databaseManager = DatabaseManager()

    // MARK: - Anagram Solver

    func findAnagrams(for letters: String, minLength: Int = 3) -> [AnagramResult] {
        let normalizedLetters = letters.lowercased().filter { $0.isLetter }
        guard normalizedLetters.count >= minLength else { return [] }

        let allWords = databaseManager.getAllWords()
        var results: [AnagramResult] = []

        for word in allWords {
            if word.count >= minLength && word.count <= normalizedLetters.count {
                if isAnagram(word: word, letters: normalizedLetters) {
                    results.append(AnagramResult(
                        word: word,
                        score: ScrabbleScorer.score(word: word),
                        length: word.count
                    ))
                }
            }
        }

        return results.sorted { $0.score > $1.score }
    }

    private func isAnagram(word: String, letters: String) -> Bool {
        var availableLetters = Array(letters)

        for char in word {
            if let index = availableLetters.firstIndex(of: char) {
                availableLetters.remove(at: index)
            } else {
                return false
            }
        }

        return true
    }

    // MARK: - Crossword Helper

    func findCrosswordMatches(pattern: String) -> [String] {
        let crosswordPattern = CrosswordPattern(pattern: pattern)
        let allWords = databaseManager.getAllWords()

        return allWords.filter { crosswordPattern.matches($0) }
            .sorted()
            .prefix(100)
            .map { $0 }
    }

    // MARK: - Scrabble Scorer

    func scoreWord(_ word: String) -> Int {
        return ScrabbleScorer.score(word: word)
    }

    func findHighScoringWords(from letters: String, limit: Int = 20) -> [AnagramResult] {
        let anagrams = findAnagrams(for: letters, minLength: 2)
        return Array(anagrams.prefix(limit))
    }

    // MARK: - Boggle Solver

    func solveBoggle(board: BoggleBoard, minLength: Int = 3) -> [AnagramResult] {
        let allWords = Set(databaseManager.getAllWords())
        var foundWords: Set<String> = []

        // Try starting from each cell
        for row in 0..<board.size {
            for col in 0..<board.size {
                var visited = Array(repeating: Array(repeating: false, count: board.size), count: board.size)
                findWordsFromCell(board: board, row: row, col: col, currentWord: "", visited: &visited, allWords: allWords, foundWords: &foundWords, minLength: minLength)
            }
        }

        return foundWords.map { word in
            AnagramResult(word: word, score: ScrabbleScorer.score(word: word), length: word.count)
        }.sorted { $0.score > $1.score }
    }

    private func findWordsFromCell(board: BoggleBoard, row: Int, col: Int, currentWord: String, visited: inout [[Bool]], allWords: Set<String>, foundWords: inout Set<String>, minLength: Int) {
        // Bounds check
        guard row >= 0, row < board.size, col >= 0, col < board.size, !visited[row][col] else {
            return
        }

        visited[row][col] = true
        let newWord = currentWord + String(board.grid[row][col])

        // Check if it's a valid word
        if newWord.count >= minLength && allWords.contains(newWord) {
            foundWords.insert(newWord)
        }

        // Continue searching if we haven't exceeded reasonable length
        if newWord.count < 15 {
            // Check all 8 adjacent cells
            let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
            for (dRow, dCol) in directions {
                findWordsFromCell(board: board, row: row + dRow, col: col + dCol, currentWord: newWord, visited: &visited, allWords: allWords, foundWords: &foundWords, minLength: minLength)
            }
        }

        visited[row][col] = false
    }

    // MARK: - Word Scramble

    func generateScramble(word: String) -> String {
        return String(word.shuffled())
    }

    func validateScrambleAnswer(scrambled: String, original: String, answer: String) -> Bool {
        return answer.lowercased() == original.lowercased()
    }

    // MARK: - Random Word Selection

    func getRandomWords(count: Int, minRank: Double = 0.0, maxRank: Double = 1.0) -> [String] {
        // For now, just return random words from database
        // In future, could filter by rank for difficulty levels
        let allWords = databaseManager.getAllWords()
        return Array(allWords.shuffled().prefix(count))
    }
}

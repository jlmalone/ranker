// ranker/Ranker/Models/GameModels.swift

import Foundation

// Game types and models
enum GameType: String, CaseIterable {
    case anagramSolver = "Anagram Solver"
    case wordScramble = "Word Scramble"
    case crosswordHelper = "Crossword Helper"
    case scrabbleScorer = "Scrabble Scorer"
    case boggleSolver = "Boggle Solver"
}

// Anagram result
struct AnagramResult: Identifiable {
    let id = UUID()
    let word: String
    let score: Int
    let length: Int
}

// Scrabble letter values
struct ScrabbleScorer {
    static let letterValues: [Character: Int] = [
        "a": 1, "e": 1, "i": 1, "o": 1, "u": 1, "l": 1, "n": 1, "s": 1, "t": 1, "r": 1,
        "d": 2, "g": 2,
        "b": 3, "c": 3, "m": 3, "p": 3,
        "f": 4, "h": 4, "v": 4, "w": 4, "y": 4,
        "k": 5,
        "j": 8, "x": 8,
        "q": 10, "z": 10
    ]

    static func score(word: String) -> Int {
        word.lowercased().reduce(0) { sum, char in
            sum + (letterValues[char] ?? 0)
        }
    }
}

// Boggle board
struct BoggleBoard {
    let grid: [[Character]]
    let size: Int

    init(size: Int = 4) {
        self.size = size
        // Generate random board
        let letters = "abcdefghijklmnoprstuvwy" // No q, x, z for easier gameplay
        self.grid = (0..<size).map { _ in
            (0..<size).map { _ in
                letters.randomElement()!
            }
        }
    }

    init(grid: [[Character]]) {
        self.grid = grid
        self.size = grid.count
    }
}

// Crossword pattern
struct CrosswordPattern {
    let pattern: String  // e.g., "c?t" where ? is unknown
    let length: Int

    init(pattern: String) {
        self.pattern = pattern.lowercased()
        self.length = pattern.count
    }

    func matches(_ word: String) -> Bool {
        guard word.count == length else { return false }

        for (index, char) in pattern.enumerated() {
            if char != "?" && char != word[word.index(word.startIndex, offsetBy: index)] {
                return false
            }
        }
        return true
    }
}

// Game score for leaderboard
struct GameScore: Identifiable {
    let id = UUID()
    let gameType: GameType
    let score: Int
    let timestamp: Date
    let details: String
}

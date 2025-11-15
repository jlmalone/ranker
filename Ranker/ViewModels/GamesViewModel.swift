// ranker/Ranker/ViewModels/GamesViewModel.swift

import Foundation
import Combine

class GamesViewModel: ObservableObject {
    @Published var selectedGame: GameType?
    @Published var anagramLetters = ""
    @Published var anagramResults: [AnagramResult] = []
    @Published var crosswordPattern = ""
    @Published var crosswordResults: [String] = []
    @Published var scrabbleWord = ""
    @Published var scrabbleScore: Int = 0
    @Published var boggleBoard: BoggleBoard?
    @Published var boggleResults: [AnagramResult] = []
    @Published var scrambledWord = ""
    @Published var originalWord = ""
    @Published var scrambleAnswer = ""
    @Published var isScrambleCorrect: Bool?

    private let gameEngine = GameEngine()
    private let databaseManager = DatabaseManager()

    // MARK: - Anagram Solver

    func solveAnagrams() {
        guard !anagramLetters.isEmpty else {
            anagramResults = []
            return
        }

        anagramResults = gameEngine.findAnagrams(for: anagramLetters, minLength: 3)
    }

    // MARK: - Crossword Helper

    func solveCrossword() {
        guard !crosswordPattern.isEmpty else {
            crosswordResults = []
            return
        }

        crosswordResults = gameEngine.findCrosswordMatches(pattern: crosswordPattern)
    }

    // MARK: - Scrabble Scorer

    func calculateScrabbleScore() {
        guard !scrabbleWord.isEmpty else {
            scrabbleScore = 0
            return
        }

        scrabbleScore = gameEngine.scoreWord(scrabbleWord)
    }

    func findHighScoringWords() {
        guard !anagramLetters.isEmpty else {
            anagramResults = []
            return
        }

        anagramResults = gameEngine.findHighScoringWords(from: anagramLetters, limit: 20)
    }

    // MARK: - Boggle Solver

    func generateBoggleBoard() {
        boggleBoard = BoggleBoard(size: 4)
        boggleResults = []
    }

    func solveBoggleBoard() {
        guard let board = boggleBoard else { return }

        boggleResults = gameEngine.solveBoggle(board: board, minLength: 3)

        // Save high score
        let score = boggleResults.reduce(0) { $0 + $1.score }
        let gameScore = GameScore(
            gameType: .boggleSolver,
            score: score,
            timestamp: Date(),
            details: "\(boggleResults.count) words found"
        )
        databaseManager.saveGameScore(gameScore)
    }

    // MARK: - Word Scramble

    func startNewScramble() {
        let words = gameEngine.getRandomWords(count: 1, minRank: 0.6, maxRank: 1.0)
        guard let word = words.first else { return }

        originalWord = word
        scrambledWord = gameEngine.generateScramble(word: word)
        scrambleAnswer = ""
        isScrambleCorrect = nil
    }

    func checkScrambleAnswer() {
        isScrambleCorrect = gameEngine.validateScrambleAnswer(
            scrambled: scrambledWord,
            original: originalWord,
            answer: scrambleAnswer
        )

        if isScrambleCorrect == true {
            let gameScore = GameScore(
                gameType: .wordScramble,
                score: originalWord.count * 10,
                timestamp: Date(),
                details: "Unscrambled: \(originalWord)"
            )
            databaseManager.saveGameScore(gameScore)
        }
    }

    // MARK: - High Scores

    func getHighScores(for gameType: GameType) -> [GameScore] {
        return databaseManager.fetchHighScores(gameType: gameType, limit: 10)
    }
}

// ranker/Ranker/ViewModels/LearningViewModel.swift

import Foundation
import Combine

class LearningViewModel: ObservableObject {
    @Published var dueFlashcards: [Flashcard] = []
    @Published var currentFlashcard: Flashcard?
    @Published var currentFlashcardIndex = 0
    @Published var showAnswer = false
    @Published var wordOfTheDay = ""
    @Published var progressStats: ProgressStatistics?
    @Published var quizStats: QuizStatistics?
    @Published var currentQuiz: [QuizQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var quizAnswer = ""
    @Published var quizComplete = false

    private let learningService = LearningService()
    private let dictionaryService = DictionaryService()

    init() {
        loadWordOfTheDay()
        loadProgress()
    }

    // MARK: - Flashcards

    func loadDueFlashcards() {
        dueFlashcards = learningService.getDueFlashcards(limit: 20)
        currentFlashcardIndex = 0
        showAnswer = false

        if !dueFlashcards.isEmpty {
            currentFlashcard = dueFlashcards[0]
        }
    }

    func toggleAnswer() {
        showAnswer.toggle()
    }

    func rateFlashcard(quality: Int) {
        guard currentFlashcardIndex < dueFlashcards.count else { return }

        var flashcard = dueFlashcards[currentFlashcardIndex]
        learningService.reviewFlashcard(&flashcard, quality: quality)

        // Move to next flashcard
        currentFlashcardIndex += 1
        showAnswer = false

        if currentFlashcardIndex < dueFlashcards.count {
            currentFlashcard = dueFlashcards[currentFlashcardIndex]
        } else {
            currentFlashcard = nil
        }
    }

    func addWordToFlashcards(word: String) {
        learningService.createFlashcard(for: word)
    }

    // MARK: - Quizzes

    func startDefinitionQuiz() {
        currentQuiz = learningService.generateDefinitionQuiz(wordCount: 10)
        currentQuestionIndex = 0
        quizAnswer = ""
        quizComplete = false
    }

    func startSynonymQuiz() {
        currentQuiz = learningService.generateSynonymQuiz(wordCount: 10)
        currentQuestionIndex = 0
        quizAnswer = ""
        quizComplete = false
    }

    func startSpellingQuiz() {
        currentQuiz = learningService.generateSpellingQuiz(wordCount: 10)
        currentQuestionIndex = 0
        quizAnswer = ""
        quizComplete = false
    }

    func submitQuizAnswer() {
        guard currentQuestionIndex < currentQuiz.count else { return }

        currentQuiz[currentQuestionIndex].userAnswer = quizAnswer

        let question = currentQuiz[currentQuestionIndex]
        learningService.saveQuizResult(
            word: question.word,
            correct: question.isCorrect,
            quizType: question.type
        )

        // Move to next question
        currentQuestionIndex += 1
        quizAnswer = ""

        if currentQuestionIndex >= currentQuiz.count {
            quizComplete = true
            loadQuizStats()
        }
    }

    func getQuizScore() -> (correct: Int, total: Int) {
        let correct = currentQuiz.filter { $0.isCorrect }.count
        return (correct, currentQuiz.count)
    }

    // MARK: - Word of the Day

    func loadWordOfTheDay() {
        wordOfTheDay = learningService.getWordOfTheDay()
    }

    // MARK: - Progress

    func loadProgress() {
        progressStats = learningService.getProgressStatistics()
        loadQuizStats()
    }

    func loadQuizStats() {
        quizStats = learningService.getQuizStatistics()
    }
}

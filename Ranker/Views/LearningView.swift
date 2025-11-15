// ranker/Ranker/Views/LearningView.swift

import SwiftUI

struct LearningView: View {
    @StateObject private var viewModel = LearningViewModel()

    var body: some View {
        List {
            Section("Daily Practice") {
                NavigationLink(destination: WordOfTheDayView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                        Text("Word of the Day")
                    }
                }

                NavigationLink(destination: FlashcardsView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                            .foregroundColor(.blue)
                        Text("Flashcards")
                        if !viewModel.dueFlashcards.isEmpty {
                            Spacer()
                            Text("\(viewModel.dueFlashcards.count) due")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Section("Quizzes") {
                NavigationLink(destination: QuizSelectionView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.green)
                        Text("Take a Quiz")
                    }
                }
            }

            Section("Progress") {
                NavigationLink(destination: ProgressView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.purple)
                        Text("My Progress")
                    }
                }
            }
        }
        .navigationTitle("Learning")
        .onAppear {
            viewModel.loadDueFlashcards()
        }
    }
}

// MARK: - Word of the Day View

struct WordOfTheDayView: View {
    @ObservedObject var viewModel: LearningViewModel
    @StateObject private var dictViewModel = DictionaryViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Word of the Day")
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.wordOfTheDay)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

            Button("Learn More") {
                dictViewModel.searchText = viewModel.wordOfTheDay
                dictViewModel.searchWord()
            }
            .buttonStyle(.borderedProminent)

            if dictViewModel.dictionaryEntry != nil {
                DictionaryView()
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Flashcards View

struct FlashcardsView: View {
    @ObservedObject var viewModel: LearningViewModel

    var body: some View {
        VStack {
            if let flashcard = viewModel.currentFlashcard {
                VStack(spacing: 30) {
                    // Progress indicator
                    Text("Card \(viewModel.currentFlashcardIndex + 1) of \(viewModel.dueFlashcards.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Flashcard
                    VStack(spacing: 20) {
                        Text(flashcard.word)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                            .padding()

                        if viewModel.showAnswer {
                            Text("Review this word and rate your recall")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Tap to reveal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    .onTapGesture {
                        viewModel.toggleAnswer()
                    }

                    if viewModel.showAnswer {
                        VStack(spacing: 16) {
                            Text("How well did you recall?")
                                .font(.headline)

                            HStack(spacing: 12) {
                                ForEach(0..<6) { quality in
                                    Button(action: {
                                        viewModel.rateFlashcard(quality: quality)
                                    }) {
                                        Text("\(quality)")
                                            .font(.headline)
                                            .frame(width: 50, height: 50)
                                            .background(colorForQuality(quality))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                            }

                            Text("0 = No recall, 5 = Perfect recall")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("All done!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("No more flashcards due for review")
                        .foregroundColor(.secondary)

                    Button("Load More") {
                        viewModel.loadDueFlashcards()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Flashcards")
        .onAppear {
            viewModel.loadDueFlashcards()
        }
    }

    private func colorForQuality(_ quality: Int) -> Color {
        switch quality {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        case 4: return .blue
        case 5: return .purple
        default: return .gray
        }
    }
}

// MARK: - Quiz Selection View

struct QuizSelectionView: View {
    @ObservedObject var viewModel: LearningViewModel

    var body: some View {
        List {
            Button(action: {
                viewModel.startDefinitionQuiz()
            }) {
                HStack {
                    Image(systemName: "book")
                        .foregroundColor(.blue)
                    Text("Definition Quiz")
                }
            }

            Button(action: {
                viewModel.startSynonymQuiz()
            }) {
                HStack {
                    Image(systemName: "equal.circle")
                        .foregroundColor(.green)
                    Text("Synonym Quiz")
                }
            }

            Button(action: {
                viewModel.startSpellingQuiz()
            }) {
                HStack {
                    Image(systemName: "textformat.abc")
                        .foregroundColor(.orange)
                    Text("Spelling Quiz")
                }
            }
        }
        .navigationTitle("Select Quiz Type")
        .navigationDestination(isPresented: .constant(!viewModel.currentQuiz.isEmpty)) {
            QuizView(viewModel: viewModel)
        }
    }
}

// MARK: - Quiz View

struct QuizView: View {
    @ObservedObject var viewModel: LearningViewModel

    var body: some View {
        VStack(spacing: 20) {
            if !viewModel.quizComplete {
                // Progress
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.currentQuiz.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.currentQuestionIndex < viewModel.currentQuiz.count {
                    let question = viewModel.currentQuiz[viewModel.currentQuestionIndex]

                    VStack(spacing: 20) {
                        Text(question.word)
                            .font(.system(size: 36, weight: .bold))
                            .padding()

                        TextField("Your answer", text: $viewModel.quizAnswer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding()

                        Button("Submit") {
                            viewModel.submitQuizAnswer()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                // Quiz complete
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    let score = viewModel.getQuizScore()
                    Text("\(score.correct) / \(score.total)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)

                    Text(String(format: "%.1f%% Correct", Double(score.correct) / Double(score.total) * 100))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Quiz")
    }
}

// MARK: - Progress View

struct ProgressView: View {
    @ObservedObject var viewModel: LearningViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let stats = viewModel.progressStats {
                    // Words Progress
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Words")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Reviewed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.reviewedWords)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.totalWords)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }

                        ProgressViewBar(value: stats.reviewedPercentage)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Quiz Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quiz Statistics")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Quizzes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.totalQuizzes)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Accuracy")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", stats.overallAccuracy * 100))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }

                        Text("Recent Accuracy: \(String(format: "%.1f%%", stats.recentAccuracy * 100))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Streak
                    VStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("\(stats.streak) Day Streak!")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Progress")
        .onAppear {
            viewModel.loadProgress()
        }
    }
}

struct ProgressViewBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(value), height: 8)
            }
        }
        .frame(height: 8)
        .cornerRadius(4)
    }
}

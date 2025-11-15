// ranker/Ranker/Views/GamesView.swift

import SwiftUI

struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()

    var body: some View {
        List {
            ForEach(GameType.allCases, id: \.self) { gameType in
                NavigationLink(destination: gameDetailView(for: gameType)) {
                    HStack {
                        Image(systemName: iconFor(gameType))
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 40)

                        Text(gameType.rawValue)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Word Games")
    }

    @ViewBuilder
    private func gameDetailView(for gameType: GameType) -> some View {
        switch gameType {
        case .anagramSolver:
            AnagramSolverView(viewModel: viewModel)
        case .wordScramble:
            WordScrambleView(viewModel: viewModel)
        case .crosswordHelper:
            CrosswordHelperView(viewModel: viewModel)
        case .scrabbleScorer:
            ScrabbleScorerView(viewModel: viewModel)
        case .boggleSolver:
            BoggleSolverView(viewModel: viewModel)
        }
    }

    private func iconFor(_ gameType: GameType) -> String {
        switch gameType {
        case .anagramSolver: return "shuffle"
        case .wordScramble: return "questionmark.square"
        case .crosswordHelper: return "grid"
        case .scrabbleScorer: return "number"
        case .boggleSolver: return "square.grid.4x3.fill"
        }
    }
}

// MARK: - Anagram Solver View

struct AnagramSolverView: View {
    @ObservedObject var viewModel: GamesViewModel

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter letters", text: $viewModel.anagramLetters)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            Button("Find Anagrams") {
                viewModel.solveAnagrams()
            }
            .buttonStyle(.borderedProminent)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.anagramResults) { result in
                        HStack {
                            Text(result.word)
                                .font(.headline)
                            Spacer()
                            Text("\(result.score) pts")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Anagram Solver")
    }
}

// MARK: - Word Scramble View

struct WordScrambleView: View {
    @ObservedObject var viewModel: GamesViewModel

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.scrambledWord.isEmpty {
                Button("Start New Game") {
                    viewModel.startNewScramble()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                VStack(spacing: 16) {
                    Text("Unscramble this word:")
                        .font(.headline)

                    Text(viewModel.scrambledWord)
                        .font(.system(size: 36, weight: .bold))
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)

                    TextField("Your answer", text: $viewModel.scrambleAnswer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .padding()

                    Button("Check Answer") {
                        viewModel.checkScrambleAnswer()
                    }
                    .buttonStyle(.borderedProminent)

                    if let isCorrect = viewModel.isScrambleCorrect {
                        if isCorrect {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                Text("Correct!")
                                    .font(.title)
                                    .fontWeight(.bold)

                                Button("Next Word") {
                                    viewModel.startNewScramble()
                                }
                                .padding(.top)
                            }
                        } else {
                            VStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)
                                Text("Try again!")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Word Scramble")
    }
}

// MARK: - Crossword Helper View

struct CrosswordHelperView: View {
    @ObservedObject var viewModel: GamesViewModel

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Use ? for unknown letters")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter pattern (e.g., c?t)", text: $viewModel.crosswordPattern)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
            .padding()

            Button("Find Matches") {
                viewModel.solveCrossword()
            }
            .buttonStyle(.borderedProminent)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.crosswordResults, id: \.self) { word in
                        Text(word)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Crossword Helper")
    }
}

// MARK: - Scrabble Scorer View

struct ScrabbleScorerView: View {
    @ObservedObject var viewModel: GamesViewModel

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter word", text: $viewModel.scrabbleWord)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()
                .onChange(of: viewModel.scrabbleWord) { _ in
                    viewModel.calculateScrabbleScore()
                }

            if viewModel.scrabbleScore > 0 {
                VStack {
                    Text("Score")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.scrabbleScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }

            Divider()

            Text("Find High-Scoring Words")
                .font(.headline)

            TextField("Enter available letters", text: $viewModel.anagramLetters)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            Button("Find Best Words") {
                viewModel.findHighScoringWords()
            }
            .buttonStyle(.borderedProminent)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.anagramResults) { result in
                        HStack {
                            Text(result.word)
                                .font(.headline)
                            Spacer()
                            Text("\(result.score) pts")
                                .foregroundColor(.blue)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Scrabble Scorer")
    }
}

// MARK: - Boggle Solver View

struct BoggleSolverView: View {
    @ObservedObject var viewModel: GamesViewModel

    var body: some View {
        VStack(spacing: 20) {
            if let board = viewModel.boggleBoard {
                VStack(spacing: 4) {
                    ForEach(0..<board.size, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<board.size, id: \.self) { col in
                                Text(String(board.grid[row][col]).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()

                Button("Solve Board") {
                    viewModel.solveBoggleBoard()
                }
                .buttonStyle(.borderedProminent)

                if !viewModel.boggleResults.isEmpty {
                    Text("Found \(viewModel.boggleResults.count) words!")
                        .font(.headline)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.boggleResults.prefix(50)) { result in
                                HStack {
                                    Text(result.word)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(result.score) pts")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
            } else {
                Button("Generate New Board") {
                    viewModel.generateBoggleBoard()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Boggle Solver")
    }
}

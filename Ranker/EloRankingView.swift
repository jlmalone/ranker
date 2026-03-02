import SwiftUI

struct EloRankingView: View {
    @StateObject private var viewModel = EloRankingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let pair = viewModel.currentPair {
                    Text("Which FEELS more like something you'd use as a password?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    HStack(spacing: 20) {
                        wordCard(pair.0) {
                            viewModel.choose(winner: pair.0, loser: pair.1)
                        }
                        Text("vs")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        wordCard(pair.1) {
                            viewModel.choose(winner: pair.1, loser: pair.0)
                        }
                    }
                    .padding(.horizontal)

                    Text("\(viewModel.comparisonCount) comparisons done")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !viewModel.topWords.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top ranked:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.topWords.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "text.word.spacing")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Add words via Memory Dump first")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Elo Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.loadNextPair() }
        }
    }

    private func wordCard(_ word: Word, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(word.name)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

class EloRankingViewModel: ObservableObject {
    @Published var currentPair: (Word, Word)?
    @Published var comparisonCount = 0
    @Published var topWords: [Word] = []

    private let databaseManager = DatabaseManager()

    func loadNextPair() {
        currentPair = databaseManager.fetchPairForComparison()
        comparisonCount = databaseManager.countEloComparisons()
        topWords = databaseManager.fetchTopWords(limit: 5)
    }

    func choose(winner: Word, loser: Word) {
        databaseManager.recordEloComparison(wordAId: winner.id, wordBId: loser.id, winnerId: winner.id)
        loadNextPair()
    }
}

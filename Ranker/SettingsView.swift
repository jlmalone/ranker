import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @State private var showExport = false

    var body: some View {
        NavigationStack {
            List {
                Section("Database") {
                    row("Total words", "\(viewModel.totalWords)")
                    row("Active (rank >= 0.06)", "\(viewModel.activeWords)")
                    row("Eliminated", "\(viewModel.totalWords - viewModel.activeWords)")
                    row("Reviewed", "\(viewModel.reviewedCount)")
                    row("Elo comparisons", "\(viewModel.comparisonCount)")
                }

                Section("Attack Complexity") {
                    row("Initial keyspace", viewModel.initialKeyspaceDisplay)
                    row("Current keyspace", viewModel.currentKeyspaceDisplay)

                    HStack {
                        Text("Reduction")
                        Spacer()
                        Text(viewModel.reductionDisplay)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                }

                Section("Per Word Eliminated") {
                    Text("Removing one word of length N eliminates this many password combinations:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(3...12, id: \.self) { len in
                        let impact = ComplexityEstimator.variantsPerWord(wordLength: len)
                        row("Length \(len)", formatSci(impact))
                    }
                }

                Section("Export") {
                    Button("Export ranker_export.json") {
                        showExport = true
                    }
                }

                Section("Advanced Modes") {
                    NavigationLink("Elo Pair Ranking") {
                        EloRankingView()
                    }
                    NavigationLink("Pattern Template Ranking") {
                        PatternRankingView()
                    }
                    NavigationLink("Context Priming (2014)") {
                        ContextPrimingView(showRanking: .constant(false))
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.refresh() }
            .sheet(isPresented: $showExport) {
                ExportView()
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.system(.body, design: .monospaced))
        }
    }

    private func formatSci(_ value: Double) -> String {
        if value < 1000 { return String(format: "%.0f", value) }
        let exp = Int(log10(value))
        let mantissa = value / pow(10.0, Double(exp))
        return String(format: "%.1f × 10^%d", mantissa, exp)
    }
}

// MARK: - Complexity Estimator

struct ComplexityEstimator {
    // Modifier chars: `~!@#$%^&* (9) + digits 0-9 (10) = 19
    static let modAlpha = 19.0
    static let maxLen = 16

    /// Capitalization variants for word of length L (max 2 uppercase)
    /// C(L,0) + C(L,1) + C(L,2) = 1 + L + L*(L-1)/2
    static func capVariants(wordLength L: Int) -> Double {
        let l = Double(L)
        return 1.0 + l + l * (l - 1.0) / 2.0
    }

    /// Modifier variants: password = prefix + word + suffix
    /// prefix/suffix chars from {digits + specials}, total extra 0..(16-L)
    /// For k extra chars, (k+1) ways to split prefix/suffix, 19^k char combos
    static func modifierVariants(wordLength L: Int) -> Double {
        let maxExtra = maxLen - L
        guard maxExtra >= 0 else { return 1.0 }
        var total = 0.0
        var power = 1.0
        for k in 0...maxExtra {
            total += Double(k + 1) * power
            power *= modAlpha
        }
        return total
    }

    /// Total password variants from one word of length L
    static func variantsPerWord(wordLength L: Int) -> Double {
        return capVariants(wordLength: L) * modifierVariants(wordLength: L)
    }

    /// Total keyspace given [wordLength: wordCount]
    static func keyspace(distribution: [Int: Int]) -> Double {
        var total = 0.0
        for (len, count) in distribution {
            total += Double(count) * variantsPerWord(wordLength: len)
        }
        return total
    }
}

// MARK: - ViewModel

class SettingsViewModel: ObservableObject {
    @Published var totalWords = 0
    @Published var activeWords = 0
    @Published var reviewedCount = 0
    @Published var comparisonCount = 0
    @Published var initialKeyspaceDisplay = "..."
    @Published var currentKeyspaceDisplay = "..."
    @Published var reductionDisplay = "..."

    private let databaseManager = DatabaseManager()

    func refresh() {
        totalWords = databaseManager.countTotalWords()
        activeWords = databaseManager.countActiveWords()
        reviewedCount = databaseManager.countReviewedWords()
        comparisonCount = databaseManager.countEloComparisons()

        // Compute keyspace on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let allDist = self.databaseManager.wordLengthDistribution()
            let activeDist = self.databaseManager.activeWordLengthDistribution()

            let initial = ComplexityEstimator.keyspace(distribution: allDist)
            let current = ComplexityEstimator.keyspace(distribution: activeDist)

            let reduction = initial > 0 ? (1.0 - current / initial) * 100.0 : 0.0

            DispatchQueue.main.async {
                self.initialKeyspaceDisplay = self.formatKeyspace(initial)
                self.currentKeyspaceDisplay = self.formatKeyspace(current)
                self.reductionDisplay = String(format: "%.1f%% reduced", reduction)
            }
        }
    }

    private func formatKeyspace(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value < 1000 { return String(format: "%.0f", value) }
        let exp = Int(log10(value))
        let mantissa = value / pow(10.0, Double(exp))
        return String(format: "%.2f × 10^%d", mantissa, exp)
    }
}

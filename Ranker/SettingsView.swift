import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @State private var showExport = false

    var body: some View {
        NavigationStack {
            List {
                Section("Database") {
                    HStack {
                        Text("Total words")
                        Spacer()
                        Text("\(viewModel.totalWords)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Reviewed")
                        Spacer()
                        Text("\(viewModel.reviewedCount)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Elo comparisons")
                        Spacer()
                        Text("\(viewModel.comparisonCount)")
                            .foregroundColor(.secondary)
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
}

class SettingsViewModel: ObservableObject {
    @Published var totalWords = 0
    @Published var reviewedCount = 0
    @Published var comparisonCount = 0

    private let databaseManager = DatabaseManager()

    func refresh() {
        totalWords = databaseManager.countTotalWords()
        reviewedCount = databaseManager.countReviewedWords()
        comparisonCount = databaseManager.countEloComparisons()
    }
}

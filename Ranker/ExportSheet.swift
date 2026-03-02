import SwiftUI

struct ExportView: View {
    @StateObject private var viewModel = ExportViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text("Export Ranked Seeds")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Exports ranker_export.json following the canonical interchange format for the RANKER pipeline")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    statRow("Total words", "\(viewModel.totalWords)")
                    statRow("Elo comparisons", "\(viewModel.comparisonCount)")
                    statRow("Pattern rankings", "\(viewModel.patternCount)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                if let error = viewModel.exportError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button("Export ranker_export.json") {
                    viewModel.export()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.totalWords == 0)

                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.exportFileURL {
                    ShareSheet(items: [url])
                }
            }
            .onAppear { viewModel.loadStats() }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

class ExportViewModel: ObservableObject {
    @Published var totalWords = 0
    @Published var comparisonCount = 0
    @Published var patternCount = 0
    @Published var showShareSheet = false
    @Published var exportFileURL: URL?
    @Published var exportError: String?

    private let databaseManager = DatabaseManager()

    func loadStats() {
        totalWords = databaseManager.countTotalWords()
        comparisonCount = databaseManager.countEloComparisons()
        patternCount = databaseManager.fetchPatternRankings().count
    }

    func export() {
        guard let jsonData = databaseManager.exportToJSON() else {
            exportError = "Failed to generate export data"
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("ranker_export.json")

        do {
            try jsonData.write(to: fileURL)
            exportFileURL = fileURL
            showShareSheet = true
            exportError = nil
        } catch {
            exportError = "Failed to write file: \(error.localizedDescription)"
        }
    }
}

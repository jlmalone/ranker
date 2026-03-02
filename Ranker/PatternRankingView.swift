import SwiftUI

struct PatternItem: Identifiable {
    let id = UUID()
    var pattern: String
    var example: String
    var confidence: Double
}

struct PatternRankingView: View {
    @StateObject private var viewModel = PatternRankingViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Text("Drag to reorder \u{2014} most likely pattern at top")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                List {
                    ForEach(viewModel.patterns) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.pattern)
                                    .font(.headline)
                                Text(item.example)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0f%%", item.confidence * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { from, to in
                        viewModel.patterns.move(fromOffsets: from, toOffset: to)
                        viewModel.recalculateConfidence()
                    }
                }
                .environment(\.editMode, .constant(.active))

                Button("Save Rankings") {
                    viewModel.save()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Pattern Ranking")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

class PatternRankingViewModel: ObservableObject {
    @Published var patterns: [PatternItem] = []
    @Published var saved = false

    private let databaseManager = DatabaseManager()

    private let defaultPatterns: [(String, String)] = [
        ("word + number", "Dragon123"),
        ("Word + Special + Number", "Dragon!2014"),
        ("two words", "DragonFire"),
        ("all lowercase", "dragonfire"),
        ("ALLCAPS", "DRAGONFIRE"),
        ("l33tspeak", "Dr4g0nF1r3"),
        ("phrase", "iloveethereum"),
        ("word + year", "Dragon2014"),
        ("name + digits", "Joseph42"),
    ]

    init() {
        loadPatterns()
    }

    func loadPatterns() {
        let saved = databaseManager.fetchPatternRankings()
        if saved.isEmpty {
            patterns = defaultPatterns.enumerated().map { index, p in
                let confidence = 1.0 - (Double(index) / Double(defaultPatterns.count))
                return PatternItem(pattern: p.0, example: p.1, confidence: confidence)
            }
        } else {
            patterns = saved.map { PatternItem(pattern: $0.pattern, example: $0.example, confidence: $0.confidence) }
        }
    }

    func recalculateConfidence() {
        let count = Double(patterns.count)
        for (index, _) in patterns.enumerated() {
            patterns[index].confidence = (count - Double(index)) / count
        }
    }

    func save() {
        let data = patterns.map { (pattern: $0.pattern, example: $0.example, confidence: $0.confidence) }
        databaseManager.savePatternRankings(data)
        saved = true
    }
}

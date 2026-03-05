// WordSorterContentView: The main word browser. Slider ranking with tap-to-capture.

import Foundation
import SwiftUI

struct WordSorterContentView: View {
    @StateObject var viewModel = WordSorterViewModel()
    @State private var maxWidth: CGFloat = 100
    @State private var showingShareSheet = false
    @State private var selectedWord: Word? = nil

    let databaseManager = DatabaseManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WordFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                maxWidth = 100
                                viewModel.switchFilter(filter)
                            }) {
                                Text(filter.rawValue)
                                    .font(.caption)
                                    .fontWeight(viewModel.currentFilter == filter ? .bold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewModel.currentFilter == filter ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(viewModel.currentFilter == filter ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }

                // Stats bar
                HStack {
                    Text("\(viewModel.filterCount) \(viewModel.currentFilter.rawValue.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if viewModel.currentFilter != .unreviewed {
                        Text("Page \(viewModel.currentPage + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("\(viewModel.reviewedCount) reviewed total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                // Progress bar (for unreviewed mode)
                if viewModel.currentFilter == .unreviewed && viewModel.unreviewedCount > 0 {
                    GeometryReader { geo in
                        let total = max(viewModel.reviewedCount + viewModel.unreviewedCount, 1)
                        let progress = CGFloat(viewModel.reviewedCount) / CGFloat(total)
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geo.size.width * progress, height: 4)
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Word grid
                if viewModel.words.isEmpty {
                    Spacer()
                    Text("No words in this filter")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.fixed(maxWidth), alignment: .leading),
                            GridItem(.flexible(), alignment: .leading),
                            GridItem(.fixed(40)),
                            GridItem(.fixed(30))
                        ], alignment: .leading, spacing: 16) {
                            ForEach($viewModel.words) { $word in
                                Text(word.name)
                                    .lineLimit(1)
                                    .font(.body)
                                    .background(GeometryReader { geometry in
                                        Color.clear.onAppear {
                                            maxWidth = max(maxWidth, geometry.size.width)
                                        }
                                    })
                                    .onTapGesture {
                                        selectedWord = word
                                    }

                                CustomSlider(value: $word.rank)
                                    .frame(height: 20)

                                // Numeric rank display
                                Text(String(format: "%.0f", word.rank * 100))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(rankColor(word.rank))
                                    .frame(width: 40, alignment: .trailing)

                                Image(systemName: word.isNotable ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        word.isNotable.toggle()
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Buttons
                HStack {
                    Button("Dismiss All") {
                        dismissAllWords()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(viewModel.words.isEmpty)

                    Spacer()

                    Button("Next") {
                        viewModel.saveRankings()
                        maxWidth = 100
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.words.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(item: $selectedWord) { word in
                WordCaptureSheet(
                    word: word,
                    databaseManager: databaseManager,
                    onDismiss: {
                        selectedWord = nil
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingShareSheet) {
                let dbPath = databaseManager.databasePath()
                ShareSheet(items: [URL(fileURLWithPath: dbPath)])
            }
        }
    }

    private func dismissAllWords() {
        for i in viewModel.words.indices {
            viewModel.words[i].rank = 0.05
        }
    }

    private func rankColor(_ rank: Double) -> Color {
        if rank > 0.7 { return .green }
        if rank > 0.4 { return .orange }
        return .red
    }
}

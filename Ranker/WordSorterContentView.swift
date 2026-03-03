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
                // Progress bar
                HStack {
                    Text("\(viewModel.reviewedCount) reviewed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.unreviewedCount) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if viewModel.unreviewedCount > 0 {
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
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.fixed(maxWidth), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.fixed(30))
                    ], alignment: .leading, spacing: 20) {
                        ForEach($viewModel.words) { $word in
                            // Tap word to open capture sheet
                            Text(word.name)
                                .lineLimit(1)
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

                            Image(systemName: word.isNotable ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    word.isNotable.toggle()
                                }
                        }
                    }
                }
                .padding(.horizontal)

                // Next button
                Button("Next") {
                    viewModel.saveRankings()
                }
                .buttonStyle(.borderedProminent)
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
                    onDismiss: { selectedWord = nil }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingShareSheet) {
                let dbPath = databaseManager.databasePath()
                ShareSheet(items: [URL(fileURLWithPath: dbPath)])
            }
        }
    }
}

import Foundation
import SwiftUI

struct SearchView: View {
    @StateObject var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var editingWord: Word? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search for a word", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { oldText, newText in
                        if newText != oldText {
                            viewModel.search(for: newText)
                        }
                    }

                List {
                    ForEach(viewModel.searchResults) { word in
                        HStack {
                            NavigationLink(destination: AssociatedIdeasView(word: word.name)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(word.name)
                                        .font(.body)
                                    if word.reviewed {
                                        Text("reviewed")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            Spacer()

                            // Rank value — tap to edit
                            Button(action: { editingWord = word }) {
                                Text(String(format: "%.0f", word.rank * 100))
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(rankColor(word.rank))
                                    .frame(minWidth: 36, alignment: .trailing)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Add word bar
                HStack {
                    Text("Add new word:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("word", text: $viewModel.newWordText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                    Button("Add") {
                        viewModel.addWord()
                    }
                    .disabled(viewModel.newWordText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Search")
            .sheet(item: $editingWord) { word in
                WordRankSheet(word: word) { updatedWord in
                    viewModel.updateWord(updatedWord)
                    editingWord = nil
                    // Refresh search
                    viewModel.search(for: searchText)
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func rankColor(_ rank: Double) -> Color {
        if rank > 0.7 { return .green }
        if rank > 0.4 { return .orange }
        return .red
    }
}

// Inline rank editor sheet
struct WordRankSheet: View {
    @State var word: Word
    let onSave: (Word) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(word.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            VStack(spacing: 8) {
                Text(String(format: "%.0f", word.rank * 100))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(rankColor(word.rank))

                CustomSlider(value: $word.rank)
                    .frame(height: 30)
                    .padding(.horizontal, 20)

                HStack {
                    Text("0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("unlikely")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("maybe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("likely")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
            }

            HStack {
                Image(systemName: word.isNotable ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .font(.title2)
                    .onTapGesture { word.isNotable.toggle() }
                Text(word.isNotable ? "Notable" : "Not notable")
                    .foregroundColor(.secondary)
            }

            Button("Save") {
                onSave(word)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    private func rankColor(_ rank: Double) -> Color {
        if rank > 0.7 { return .green }
        if rank > 0.4 { return .orange }
        return .red
    }
}

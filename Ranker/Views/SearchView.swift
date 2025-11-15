// ranker/Ranker/Views/SearchView.swift

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // Search mode picker
            Picker("Search Mode", selection: $viewModel.searchMode) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            if viewModel.searchMode == .advanced {
                // Advanced search filters
                VStack(spacing: 12) {
                    TextField("Pattern (use ? for single, * for multiple)", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    HStack {
                        TextField("Min length", text: $viewModel.minLength)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)

                        TextField("Max length", text: $viewModel.maxLength)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }

                    TextField("Starts with", text: $viewModel.startsWith)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)

                    TextField("Ends with", text: $viewModel.endsWith)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)

                    TextField("Contains", text: $viewModel.contains)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)

                    HStack {
                        Button("Search") {
                            viewModel.performAdvancedSearch()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            } else {
                // Simple search
                HStack {
                    TextField(placeholderText, text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .onSubmit {
                            viewModel.performSearch()
                        }

                    Button(action: { viewModel.performSearch() }) {
                        Image(systemName: "magnifyingglass")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }

            // Results
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.searchResults, id: \.self) { word in
                        Button(action: {
                            viewModel.analyzeWord(word)
                        }) {
                            HStack {
                                Text(word)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    if !viewModel.searchResults.isEmpty {
                        Text("\(viewModel.searchResults.count) results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Search")
        .sheet(item: $viewModel.wordAnalysis) { analysis in
            WordAnalysisView(analysis: analysis)
        }
    }

    private var placeholderText: String {
        switch viewModel.searchMode {
        case .pattern: return "Enter pattern (e.g., c?t)"
        case .rhyme: return "Enter word to find rhymes"
        case .alliteration: return "Enter starting letter"
        case .contains: return "Enter substring"
        case .startsWith: return "Enter prefix"
        case .endsWith: return "Enter suffix"
        case .length: return "Enter word length"
        case .advanced: return "Advanced search"
        }
    }
}

// MARK: - Word Analysis View

struct WordAnalysisView: View {
    let analysis: WordAnalysis

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Word
                    Text(analysis.word)
                        .font(.system(size: 48, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)

                    // Basic stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.title2)
                            .fontWeight(.bold)

                        StatRow(label: "Length", value: "\(analysis.length) letters")
                        StatRow(label: "Vowels", value: "\(analysis.vowelCount)")
                        StatRow(label: "Consonants", value: "\(analysis.consonantCount)")
                        StatRow(label: "Unique Letters", value: "\(analysis.uniqueLetters)")
                        StatRow(label: "Scrabble Score", value: "\(analysis.scrabbleScore) points")
                        StatRow(label: "Palindrome", value: analysis.isPalindrome ? "Yes" : "No")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Letter frequency
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Letter Frequency")
                            .font(.title2)
                            .fontWeight(.bold)

                        ForEach(analysis.letterFrequency.sorted(by: { $0.key < $1.key }), id: \.key) { letter, count in
                            HStack {
                                Text(String(letter).uppercased())
                                    .font(.headline)
                                    .frame(width: 30)
                                Spacer()
                                Text("×\(count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

extension WordAnalysis: Identifiable {
    var id: String { word }
}

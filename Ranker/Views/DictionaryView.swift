// ranker/Ranker/Views/DictionaryView.swift

import SwiftUI

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // Search bar
            HStack {
                TextField("Enter a word", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .onSubmit {
                        viewModel.searchWord()
                    }

                Button(action: { viewModel.searchWord() }) {
                    Image(systemName: "magnifyingglass")
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let entry = viewModel.dictionaryEntry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Word and phonetic
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(entry.word.capitalized)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)

                                Spacer()

                                Button(action: { viewModel.addToFavorites() }) {
                                    Image(systemName: "star")
                                        .font(.title2)
                                }
                            }

                            if let phonetic = entry.phonetic {
                                HStack {
                                    Text(phonetic)
                                        .font(.title3)
                                        .foregroundColor(.secondary)

                                    if entry.phonetics.first(where: { $0.audio != nil }) != nil {
                                        Button(action: { viewModel.playPronunciation() }) {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)

                        // Etymology
                        if let origin = entry.origin {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Etymology")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Text(origin)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }

                        // Meanings
                        ForEach(entry.meanings) { meaning in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(meaning.partOfSpeech)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .italic()

                                ForEach(meaning.definitions.prefix(3)) { definition in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .top) {
                                            Text("•")
                                            Text(definition.definition)
                                        }

                                        if let example = definition.example {
                                            Text("\"" + example + "\"")
                                                .italic()
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 16)
                                        }
                                    }
                                }

                                // Synonyms
                                if !meaning.synonyms.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Synonyms:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Text(meaning.synonyms.prefix(5).joined(separator: ", "))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // Antonyms
                                if !meaning.antonyms.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Antonyms:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Text(meaning.antonyms.prefix(5).joined(separator: ", "))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            } else {
                VStack {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Search for a word to see its definition")
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Dictionary")
    }
}

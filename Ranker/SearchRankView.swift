// SearchRankView: Search for words by substring, then rank them in batches of 40 with sliders.

import Foundation
import SwiftUI

struct SearchRankView: View {
    @StateObject private var viewModel = SearchRankViewModel()
    @State private var searchText = ""
    @State private var maxWidth: CGFloat = 100
    @State private var showAllRanked = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search substring...", text: $searchText)
                        .focused($searchFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            searchFocused = false
                            performSearch()
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.clear()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    Button("Search") {
                        searchFocused = false
                        performSearch()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(searchText.trimmingCharacters(in: .whitespaces).count < 2)
                }
                .padding()

                // Unranked-only toggle
                Toggle(isOn: Binding(
                    get: { !showAllRanked },
                    set: { newValue in
                        showAllRanked = !newValue
                        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                            performSearch()
                        }
                    }
                )) {
                    Text("Unranked only")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                // Results info — tap to dismiss keyboard
                if viewModel.totalMatches > 0 {
                    HStack {
                        Text("\(viewModel.totalMatches) matches")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    .onTapGesture { searchFocused = false }
                }

                // Slider grid (same layout as Browse)
                if viewModel.words.isEmpty && viewModel.totalMatches > 0 {
                    Spacer()
                    Text("No more results on this page")
                        .foregroundColor(.secondary)
                    Spacer()
                } else if viewModel.words.isEmpty {
                    Spacer()
                    Text("Search for a substring to find words")
                        .foregroundColor(.secondary)
                        .font(.body)
                        .onTapGesture { searchFocused = false }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.fixed(maxWidth), alignment: .leading),
                            GridItem(.flexible(), alignment: .leading),
                            GridItem(.fixed(30))
                        ], alignment: .leading, spacing: 20) {
                            ForEach($viewModel.words) { $word in
                                Text(word.name)
                                    .lineLimit(1)
                                    .font(.body)
                                    .background(GeometryReader { geometry in
                                        Color.clear.onAppear {
                                            maxWidth = max(maxWidth, geometry.size.width)
                                        }
                                    })

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
                    .scrollDismissesKeyboard(.immediately)
                }

                // Bottom controls
                HStack {
                    Button("Dismiss All") {
                        for i in viewModel.words.indices {
                            viewModel.words[i].rank = 0.05
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(viewModel.words.isEmpty)

                    Spacer()

                    Button(action: { viewModel.previousPage() }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(viewModel.currentPage == 0)

                    Button("Save & Next") {
                        searchFocused = false
                        viewModel.saveAndNextPage()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.words.isEmpty)

                    Button(action: {
                        searchFocused = false
                        viewModel.saveAndNextPage()
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(viewModel.currentPage >= viewModel.totalPages - 1 && viewModel.words.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Search & Rank")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture { searchFocused = false }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { searchFocused = false }
                }
            }
        }
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else { return }
        maxWidth = 100
        viewModel.search(query: query, unrankedOnly: !showAllRanked)
    }
}

class SearchRankViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var totalMatches = 0
    @Published var currentPage = 0

    private let databaseManager = DatabaseManager()
    private let batchSize = 40
    private var currentQuery = ""
    private var unrankedOnly = true

    var totalPages: Int {
        max(1, Int(ceil(Double(totalMatches) / Double(batchSize))))
    }

    func search(query: String, unrankedOnly: Bool = true) {
        currentQuery = query
        self.unrankedOnly = unrankedOnly
        currentPage = 0
        totalMatches = databaseManager.countSearchResults(query: query, unrankedOnly: unrankedOnly)
        loadPage()
    }

    func clear() {
        words = []
        totalMatches = 0
        currentPage = 0
        currentQuery = ""
    }

    func saveAndNextPage() {
        for word in words {
            databaseManager.updateWord(word: word)
        }

        if currentPage + 1 < totalPages {
            currentPage += 1
            loadPage()
        } else {
            words = []
        }
    }

    func previousPage() {
        for word in words {
            databaseManager.updateWord(word: word)
        }

        if currentPage > 0 {
            currentPage -= 1
            loadPage()
        }
    }

    private func loadPage() {
        let offset = currentPage * batchSize
        words = databaseManager.searchWordsPaginated(
            query: currentQuery,
            batchSize: batchSize,
            offset: offset,
            unrankedOnly: unrankedOnly
        )
    }
}

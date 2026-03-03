// WordCorpusView: Tab 2 — Load words into the system from multiple sources.

import SwiftUI
import UniformTypeIdentifiers

struct WordCorpusView: View {
    @StateObject private var viewModel = WordCorpusViewModel()
    @State private var pasteText = ""
    @State private var showFilePicker = false
    @State private var showMemoryDump = false

    var body: some View {
        NavigationStack {
            List {
                // Stats
                Section {
                    HStack {
                        Text("Words in corpus")
                        Spacer()
                        Text("\(viewModel.totalWords)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Unreviewed")
                        Spacer()
                        Text("\(viewModel.unreviewedWords)")
                            .foregroundColor(.secondary)
                    }
                }

                // Bundled corpora
                Section("Load Bundled Words") {
                    Button(action: { viewModel.loadPasswordRoots() }) {
                        HStack {
                            Image(systemName: "key.fill")
                            VStack(alignment: .leading) {
                                Text("Common Password Roots")
                                Text("~5,000 base words from password frequency analysis")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)

                    Button(action: { viewModel.loadContext2014() }) {
                        HStack {
                            Image(systemName: "calendar")
                            VStack(alignment: .leading) {
                                Text("2014 Context Words")
                                Text("Crypto, pop culture, tech, events from the presale era")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                // Paste words
                Section("Paste Words") {
                    TextEditor(text: $pasteText)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if pasteText.isEmpty {
                                    Text("Paste words here (one per line, or comma/space separated)")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                }
                            },
                            alignment: .topLeading
                        )

                    if !pasteText.isEmpty {
                        let count = viewModel.countWords(in: pasteText)
                        Button("Add \(count) words") {
                            viewModel.importPastedWords(pasteText)
                            pasteText = ""
                        }
                    }
                }

                // Import from file
                Section("Import") {
                    Button(action: { showFilePicker = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            VStack(alignment: .leading) {
                                Text("Import from File")
                                Text(".txt (one per line) or .json (ranker_export.json)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Guided brainstorm (relocated from MemoryDumpView)
                Section("Guided Brainstorm") {
                    Button(action: { showMemoryDump = true }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            VStack(alignment: .leading) {
                                Text("Memory Dump Prompts")
                                Text("6 guided prompts to surface forgotten words")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Words")
            .onAppear { viewModel.refresh() }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.plainText, .json]) { result in
                switch result {
                case .success(let url):
                    viewModel.importFromFile(url)
                case .failure(let error):
                    viewModel.statusMessage = "Import failed: \(error.localizedDescription)"
                }
            }
            .sheet(isPresented: $showMemoryDump) {
                MemoryDumpView()
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        VStack {
                            SwiftUI.ProgressView("Loading...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }
                }
            )
            .alert("Import Result", isPresented: $viewModel.showStatus) {
                Button("OK") {}
            } message: {
                Text(viewModel.statusMessage)
            }
        }
    }
}

class WordCorpusViewModel: ObservableObject {
    @Published var totalWords = 0
    @Published var unreviewedWords = 0
    @Published var isLoading = false
    @Published var showStatus = false
    @Published var statusMessage = ""

    private let databaseManager = DatabaseManager()

    func refresh() {
        totalWords = databaseManager.countTotalWords()
        unreviewedWords = databaseManager.countUnreviewedWords()
    }

    func countWords(in text: String) -> Int {
        return parseWords(from: text).count
    }

    func importPastedWords(_ text: String) {
        let words = parseWords(from: text)
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var added = 0
            for word in words {
                self.databaseManager.insertWordFromDump(word, wordSource: "paste")
                added += 1
            }
            DispatchQueue.main.async {
                self.isLoading = false
                self.statusMessage = "Added \(added) words"
                self.showStatus = true
                self.refresh()
            }
        }
    }

    func loadPasswordRoots() {
        loadBundledFile(named: "password_roots", source: "password_corpus")
    }

    func loadContext2014() {
        loadBundledFile(named: "context_2014", source: "context_2014")
    }

    func importFromFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            statusMessage = "Cannot access file"
            showStatus = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                var added = 0

                if url.pathExtension == "json" {
                    // Try ranker_export.json format
                    if let data = content.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let seeds = json["seeds"] as? [[String: Any]] {
                        for seed in seeds {
                            if let word = seed["word"] as? String {
                                self.databaseManager.insertWordFromDump(word, wordSource: "import")
                                added += 1
                            }
                        }
                    }
                } else {
                    // Plain text, one per line
                    let words = self.parseWords(from: content)
                    for word in words {
                        self.databaseManager.insertWordFromDump(word, wordSource: "import")
                        added += 1
                    }
                }

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Imported \(added) words from \(url.lastPathComponent)"
                    self.showStatus = true
                    self.refresh()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Error reading file: \(error.localizedDescription)"
                    self.showStatus = true
                }
            }
        }
    }

    private func loadBundledFile(named name: String, source: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt") else {
            statusMessage = "\(name).txt not found in app bundle"
            showStatus = true
            return
        }

        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let words = self.parseWords(from: content)
                var added = 0
                for word in words {
                    self.databaseManager.insertWordFromDump(word, wordSource: source)
                    added += 1
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Loaded \(added) words from \(name)"
                    self.showStatus = true
                    self.refresh()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Error loading \(name): \(error.localizedDescription)"
                    self.showStatus = true
                }
            }
        }
    }

    func parseWords(from text: String) -> [String] {
        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;|"))
        let tokens = text.components(separatedBy: separators)
        var unique = Set<String>()
        for token in tokens {
            let cleaned = token.trimmingCharacters(in: .punctuationCharacters).lowercased()
            if cleaned.count >= 2 { unique.insert(cleaned) }
        }
        return Array(unique).sorted()
    }
}

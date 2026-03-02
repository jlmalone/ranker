import SwiftUI

struct MemoryDumpView: View {
    @StateObject private var viewModel = MemoryDumpViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.isComplete {
                    completionView
                } else {
                    promptView
                }
            }
            .padding()
            .navigationTitle("Memory Dump")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var promptView: some View {
        VStack(spacing: 16) {
            Text("Prompt \(viewModel.currentIndex + 1) of \(viewModel.prompts.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(viewModel.currentPrompt)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextEditor(text: $viewModel.currentText)
                .frame(minHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            HStack(spacing: 16) {
                Button("Skip") {
                    viewModel.skip()
                }
                .foregroundColor(.secondary)

                Spacer()

                Button("Next") {
                    viewModel.saveAndAdvance()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Memory Dump Complete")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(viewModel.wordsAdded) unique words added to your seed corpus")
                .font(.body)
                .foregroundColor(.secondary)

            if !viewModel.parsedWords.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(viewModel.parsedWords, id: \.self) { word in
                            Text(word)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            Button("Start Another Round") {
                viewModel.reset()
            }
            .buttonStyle(.bordered)
        }
    }
}

class MemoryDumpViewModel: ObservableObject {
    let prompts = [
        "Type every password you can remember ever using \u{2014} any era, any service",
        "Words associated with 2014 for you \u{2014} people, places, events, feelings",
        "Names: pets, partners, family, friends, fictional characters you liked",
        "Numbers that mean something: birthdays, addresses, PINs, jersey numbers",
        "What computer/browser/OS did you use in 2014?",
        "What were you excited about when you bought ETH?"
    ]

    @Published var currentIndex = 0
    @Published var currentText = ""
    @Published var isComplete = false
    @Published var wordsAdded = 0
    @Published var parsedWords: [String] = []

    private let databaseManager = DatabaseManager()
    private var savedTexts: [String] = []

    var currentPrompt: String {
        prompts[currentIndex]
    }

    func saveAndAdvance() {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        databaseManager.saveMemoryDump(prompt: currentPrompt, content: text)
        savedTexts.append(text)
        advance()
    }

    func skip() {
        advance()
    }

    private func advance() {
        currentText = ""
        if currentIndex + 1 < prompts.count {
            currentIndex += 1
        } else {
            parseAndInsertWords()
            isComplete = true
        }
    }

    private func parseAndInsertWords() {
        let allText = savedTexts.joined(separator: " ")

        // Split on common delimiters: spaces, commas, newlines, semicolons
        let separators = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: ",;/|"))
        let rawTokens = allText.components(separatedBy: separators)

        var uniqueWords = Set<String>()
        for token in rawTokens {
            let cleaned = token
                .trimmingCharacters(in: .punctuationCharacters)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard !cleaned.isEmpty, cleaned.count >= 2 else { continue }
            uniqueWords.insert(cleaned)
        }

        parsedWords = Array(uniqueWords).sorted()

        let countBefore = databaseManager.countTotalWords()
        for word in parsedWords {
            databaseManager.insertWordFromDump(word)
        }
        let countAfter = databaseManager.countTotalWords()
        wordsAdded = countAfter - countBefore
    }

    func reset() {
        currentIndex = 0
        currentText = ""
        isComplete = false
        wordsAdded = 0
        parsedWords = []
        savedTexts = []
    }
}

import SwiftUI

struct AssociatedIdeasView: View {
    let word: String

    @StateObject private var viewModel: AssociationChainViewModel

    init(word: String) {
        self.word = word
        _viewModel = StateObject(wrappedValue: AssociationChainViewModel(startWord: word))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chain display
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.chain.enumerated()), id: \.offset) { index, link in
                        chainNode(link.word, isStart: index == 0)
                        if index < viewModel.chain.count - 1 {
                            chainArrow(label: link.label)
                        }
                    }

                    // Current end of chain — add link
                    if !viewModel.chain.isEmpty {
                        chainArrow(label: "reminds me of")
                    }
                }
                .padding()
            }

            Divider()

            // Add link input
            HStack {
                TextField("What does this remind you of?", text: $viewModel.newWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Add") {
                    viewModel.addLink()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()

            // Recorder section
            RecorderWidgetView(seedWord: word)
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle(word)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func chainNode(_ text: String, isStart: Bool) -> some View {
        Text(text)
            .font(isStart ? .title2 : .body)
            .fontWeight(isStart ? .bold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isStart ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
            .cornerRadius(8)
    }

    private func chainArrow(label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "arrow.down")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

class AssociationChainViewModel: ObservableObject {
    struct ChainLink {
        let word: String
        let label: String
    }

    @Published var chain: [ChainLink] = []
    @Published var newWord = ""

    private let databaseManager = DatabaseManager()
    private let chainUUID: String
    private let startWord: String

    init(startWord: String) {
        self.startWord = startWord
        self.chainUUID = UUID().uuidString
        self.chain = [ChainLink(word: startWord, label: "")]
    }

    func addLink() {
        let cleaned = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        let fromWord = chain.last?.word ?? startWord
        let position = chain.count

        databaseManager.addChainLink(
            fromWord: fromWord,
            toWord: cleaned,
            label: "reminds me of",
            chainUUID: chainUUID,
            position: position
        )

        chain.append(ChainLink(word: cleaned.lowercased(), label: "reminds me of"))
        newWord = ""
    }
}

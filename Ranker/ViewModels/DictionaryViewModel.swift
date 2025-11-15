// ranker/Ranker/ViewModels/DictionaryViewModel.swift

import Foundation
import Combine
import AVFoundation

class DictionaryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var dictionaryEntry: DictionaryEntry?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let dictionaryService = DictionaryService()
    private let databaseManager = DatabaseManager()
    private var audioPlayer: AVAudioPlayer?

    func searchWord() {
        guard !searchText.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        dictionaryService.fetchDefinition(for: searchText) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false

                switch result {
                case .success(let entry):
                    self?.dictionaryEntry = entry
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.dictionaryEntry = nil
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func playPronunciation() {
        guard let entry = dictionaryEntry,
              let audioUrl = entry.phonetics.first(where: { $0.audio != nil })?.audio,
              !audioUrl.isEmpty,
              let url = URL(string: audioUrl) else {
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }

            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.play()
                } catch {
                    print("Failed to play audio: \(error)")
                }
            }
        }.resume()
    }

    func addToFavorites() {
        guard let entry = dictionaryEntry else { return }

        if let favorites = databaseManager.getFavoritesCollection() {
            databaseManager.addWordToCollection(word: entry.word, collectionId: favorites.id)
        }
    }
}

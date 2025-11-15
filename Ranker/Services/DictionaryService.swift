// ranker/Ranker/Services/DictionaryService.swift

import Foundation

// Service for fetching dictionary data from Free Dictionary API
class DictionaryService {
    private let databaseManager = DatabaseManager()
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"

    // Fetch dictionary entry with caching
    func fetchDefinition(for word: String, completion: @escaping (Result<DictionaryEntry, Error>) -> Void) {
        // Check cache first
        if let cached = databaseManager.getCachedDictionaryEntry(for: word) {
            // Cache is valid for 30 days
            if Date().timeIntervalSince(cached.cachedAt) < 30 * 24 * 60 * 60 {
                let entry = convertCachedToDictionaryEntry(cached)
                completion(.success(entry))
                return
            }
        }

        // Fetch from API
        guard let url = URL(string: baseURL + word.lowercased()) else {
            completion(.failure(DictionaryError.invalidWord))
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(DictionaryError.noData))
                return
            }

            do {
                let entries = try JSONDecoder().decode([DictionaryEntry].self, from: data)
                guard let entry = entries.first else {
                    completion(.failure(DictionaryError.noDefinition))
                    return
                }

                // Cache the result
                self?.cacheDictionaryEntry(entry)

                completion(.success(entry))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func cacheDictionaryEntry(_ entry: DictionaryEntry) {
        guard let firstMeaning = entry.meanings.first,
              let firstDefinition = firstMeaning.definitions.first else {
            return
        }

        let synonyms = firstMeaning.synonyms.joined(separator: ", ")
        let antonyms = firstMeaning.antonyms.joined(separator: ", ")
        let audioUrl = entry.phonetics.first(where: { $0.audio != nil && !$0.audio!.isEmpty })?.audio

        let cached = CachedDictionaryEntry(
            word: entry.word,
            definition: firstDefinition.definition,
            partOfSpeech: firstMeaning.partOfSpeech,
            example: firstDefinition.example,
            etymology: entry.origin,
            phonetic: entry.phonetic,
            audioUrl: audioUrl,
            synonyms: synonyms,
            antonyms: antonyms,
            cachedAt: Date()
        )

        databaseManager.cacheDictionaryEntry(cached)
    }

    private func convertCachedToDictionaryEntry(_ cached: CachedDictionaryEntry) -> DictionaryEntry {
        let phonetic = Phonetic(text: cached.phonetic, audio: cached.audioUrl)

        let definition = Definition(
            definition: cached.definition,
            example: cached.example,
            synonyms: cached.synonyms.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) },
            antonyms: cached.antonyms.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        )

        let meaning = Meaning(
            partOfSpeech: cached.partOfSpeech,
            definitions: [definition],
            synonyms: cached.synonyms.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) },
            antonyms: cached.antonyms.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        )

        return DictionaryEntry(
            word: cached.word,
            phonetic: cached.phonetic,
            phonetics: [phonetic],
            meanings: [meaning],
            origin: cached.etymology
        )
    }
}

enum DictionaryError: Error, LocalizedError {
    case invalidWord
    case noData
    case noDefinition

    var errorDescription: String? {
        switch self {
        case .invalidWord:
            return "Invalid word"
        case .noData:
            return "No data received"
        case .noDefinition:
            return "No definition found"
        }
    }
}

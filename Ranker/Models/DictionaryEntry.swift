// ranker/Ranker/Models/DictionaryEntry.swift

import Foundation

// Dictionary entry model for word definitions and metadata
struct DictionaryEntry: Codable, Identifiable {
    let id = UUID()
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]
    let meanings: [Meaning]
    let origin: String?

    enum CodingKeys: String, CodingKey {
        case word, phonetic, phonetics, meanings, origin
    }
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
}

struct Meaning: Codable, Identifiable {
    var id = UUID()
    let partOfSpeech: String
    let definitions: [Definition]
    let synonyms: [String]
    let antonyms: [String]

    enum CodingKeys: String, CodingKey {
        case partOfSpeech, definitions, synonyms, antonyms
    }
}

struct Definition: Codable, Identifiable {
    var id = UUID()
    let definition: String
    let example: String?
    let synonyms: [String]
    let antonyms: [String]

    enum CodingKeys: String, CodingKey {
        case definition, example, synonyms, antonyms
    }
}

// Simplified cached dictionary entry for database storage
struct CachedDictionaryEntry {
    let word: String
    let definition: String
    let partOfSpeech: String
    let example: String?
    let etymology: String?
    let phonetic: String?
    let audioUrl: String?
    let synonyms: String  // Comma-separated
    let antonyms: String  // Comma-separated
    let cachedAt: Date
}

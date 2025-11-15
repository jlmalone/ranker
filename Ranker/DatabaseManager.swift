
// ranker/Ranker/DatabaseManager.swift


//DatabaseManager:
//  Uses SQLite.swift to manage a single table named words.
//  Columns: id (PK, Int64 by default for Expression<Int64>), word (String, unique), rank (Double), notable (Bool), reviewed (Bool).
//  populateInitialData: Fills the DB with all 3-letter combos and numbers 1-9999.
//  fetchUnreviewedWords: Retrieves a batch of unreviewed words randomly.
//  updateWord: Saves changes to rank, notable, and crucially, sets reviewed = true if rank is not 0.5.
//  countReviewedWords/countUnreviewedWords: For progress tracking.
//  databasePath(): Provides path to db.sqlite3 for sharing.


import Foundation
import SQLite

class DatabaseManager {
    private var db: Connection?

    // Words table
    let wordsTable = Table("words")
    let id = SQLite.Expression<Int64>("id")
    let word = SQLite.Expression<String>("word")
    let rank = SQLite.Expression<Double>("rank")
    let notable = SQLite.Expression<Bool>("notable")
    let reviewed = SQLite.Expression<Bool>("reviewed")

    // Dictionary entries table (cached API data)
    let dictionaryTable = Table("dictionary_entries")
    let dictId = SQLite.Expression<Int64>("id")
    let dictWord = SQLite.Expression<String>("word")
    let dictDefinition = SQLite.Expression<String>("definition")
    let dictPartOfSpeech = SQLite.Expression<String>("part_of_speech")
    let dictExample = SQLite.Expression<String?>("example")
    let dictEtymology = SQLite.Expression<String?>("etymology")
    let dictPhonetic = SQLite.Expression<String?>("phonetic")
    let dictAudioUrl = SQLite.Expression<String?>("audio_url")
    let dictSynonyms = SQLite.Expression<String>("synonyms")
    let dictAntonyms = SQLite.Expression<String>("antonyms")
    let dictCachedAt = SQLite.Expression<Date>("cached_at")

    // Collections table
    let collectionsTable = Table("collections")
    let collId = SQLite.Expression<Int64>("id")
    let collName = SQLite.Expression<String>("name")
    let collDescription = SQLite.Expression<String>("description")
    let collCreatedAt = SQLite.Expression<Date>("created_at")
    let collIsSystem = SQLite.Expression<Bool>("is_system")

    // Collection words junction table
    let collectionWordsTable = Table("collection_words")
    let cwCollectionId = SQLite.Expression<Int64>("collection_id")
    let cwWord = SQLite.Expression<String>("word")
    let cwAddedAt = SQLite.Expression<Date>("added_at")

    // Flashcards table
    let flashcardsTable = Table("flashcards")
    let fcWord = SQLite.Expression<String>("word")
    let fcLastReviewed = SQLite.Expression<Date?>("last_reviewed")
    let fcNextReview = SQLite.Expression<Date>("next_review")
    let fcEaseFactor = SQLite.Expression<Double>("ease_factor")
    let fcInterval = SQLite.Expression<Int64>("interval")
    let fcRepetitions = SQLite.Expression<Int64>("repetitions")

    // Quiz history table
    let quizHistoryTable = Table("quiz_history")
    let qhId = SQLite.Expression<Int64>("id")
    let qhWord = SQLite.Expression<String>("word")
    let qhCorrect = SQLite.Expression<Bool>("correct")
    let qhTimestamp = SQLite.Expression<Date>("timestamp")
    let qhQuizType = SQLite.Expression<String>("quiz_type")

    // Game scores table
    let gameScoresTable = Table("game_scores")
    let gsId = SQLite.Expression<Int64>("id")
    let gsGameType = SQLite.Expression<String>("game_type")
    let gsScore = SQLite.Expression<Int64>("score")
    let gsTimestamp = SQLite.Expression<Date>("timestamp")
    let gsDetails = SQLite.Expression<String>("details")

    init() {
        setupDatabase()
        createWordsTable()
        createDictionaryTable()
        createCollectionsTables()
        createFlashcardsTable()
        createQuizHistoryTable()
        createGameScoresTable()
        populateInitialDataIfNeeded()
        createDefaultCollections()
    }


    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/db.sqlite3")
        } catch {
            print("Unable to set up database: \(error)")
        }
    }

    // Method to return the database file path
    func databasePath() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let dbPath = "\(documentsDirectory)/db.sqlite3"
        return dbPath
    }

    func printTableSchema(tableName: String) {
            do {
                guard let db = db else {
                    print("Database connection is nil.")
                    return
                }

                let pragmaQuery = "PRAGMA table_info(\(tableName));"
                let statement = try db.prepare(pragmaQuery)

                for row in statement {
                    // Assuming the column names in the result are 'name', 'type', 'notnull', 'dflt_value', 'pk' based on SQLite's documentation
                    if let name = row[0], let type = row[1], let notnull = row[2], let dflt_value = row[3], let pk = row[4] {
                        print("Column name: \(name), Type: \(type), Not null: \(notnull), Default Value: \(dflt_value), Primary Key: \(pk)")
                    }
                }
            } catch {
                print("Failed to query table schema: \(error)")
            }

        }

    private func createWordsTable() {
        let createTable = wordsTable.create(ifNotExists: true) { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(word, unique: true)
            table.column(rank)
            table.column(notable, defaultValue: false)
            table.column(reviewed, defaultValue: false)
        }

        do {
            try db?.run(createTable)
            print("Created table or already exists.")
        } catch {
            print("Failed to create table: \(error)")
        }

        printTableSchema(tableName : "words")
    }

    private func populateInitialDataIfNeeded() {
        let alreadyPopulated = UserDefaults.standard.bool(forKey: "isDatabasePopulated")
        if !alreadyPopulated {
            populateInitialData()
            UserDefaults.standard.set(true, forKey: "isDatabasePopulated")
        }
    }

    private func populateInitialData() {
        do {
            try db?.transaction {
                // Populate with all 3-letter combinations
                let letters = Array("abcdefghijklmnopqrstuvwxyz")
                for first in letters {
                    for second in letters {
                        for third in letters {
                            let combination = "\(first)\(second)\(third)"
                            try insertWordIfNotExists(name: combination, rank: 0.5)
                        }
                    }
                }

                // Populate with numbers 1 to 9999 (1 to 4-digit numbers)
                for number in 1...9999 {
                    try insertWordIfNotExists(name: "\(number)", rank: 0.5)
                }
            }
            print("Initial data populated successfully.")
        } catch {
            print("Failed to populate initial data: \(error)")
        }
    }

    private func insertWordIfNotExists(name: String, rank: Double) throws {
        let insert = wordsTable.insert(or: .ignore, word <- name, self.rank <- rank, reviewed <- false)
        try db?.run(insert)
    }

    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
        do {
            guard let db = db else {
                print("Database connection is nil.")
                return []
            }

            // Use SQL's random() function directly in the order clause
            let query = wordsTable.filter(reviewed == false).order(SQLite.Expression<Int64>.random()).limit(batchSize)
            let rows = try db.prepare(query)
            var result: [Word] = []
            for row in rows {
                let wordItem = Word(
                    name: row[word],
                    rank: row[rank],
                    isNotable: row[notable]
                )
                result.append(wordItem)
            }
            return result
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }

    func updateWord(word: Word) {
        print("update word")
        let wordRow = wordsTable.filter(self.word == word.name)
        print("wordRow is \(wordRow)")
        do {

            let isReviewed: Bool = (word.rank != 0.5 && (word.rank > 0.500001 || word.rank < 0.49999))
            print("isReviewed \(isReviewed)")

            if try db?.run(wordRow.update(self.rank <- word.rank,  self.notable <- word.isNotable, self.reviewed <- isReviewed)) ?? 0 > 0 {
                print("Updated word: \(word.name)")
            } else {
                print("Word not found: \(word.name)")
            }
        } catch {
            print("Update failed for \(word.name): \(error)")
        }
    }


    func countReviewedWords() -> Int {
        do {
            let count = try db?.scalar(wordsTable.filter(reviewed == true).count) ?? 0
            return count
        } catch {
            print("Count reviewed words failed: \(error)")
            return 0
        }
    }

    func countUnreviewedWords() -> Int {
        do {
            let count = try db?.scalar(wordsTable.filter(reviewed == false).count) ?? 0
            return count
        } catch {
            print("Count unreviewed words failed: \(error)")
            return 0
        }
    }

    // MARK: - Dictionary Table Methods

    private func createDictionaryTable() {
        let createTable = dictionaryTable.create(ifNotExists: true) { table in
            table.column(dictId, primaryKey: .autoincrement)
            table.column(dictWord, unique: true)
            table.column(dictDefinition)
            table.column(dictPartOfSpeech)
            table.column(dictExample)
            table.column(dictEtymology)
            table.column(dictPhonetic)
            table.column(dictAudioUrl)
            table.column(dictSynonyms, defaultValue: "")
            table.column(dictAntonyms, defaultValue: "")
            table.column(dictCachedAt)
        }

        do {
            try db?.run(createTable)
            print("Dictionary table created or already exists.")
        } catch {
            print("Failed to create dictionary table: \(error)")
        }
    }

    func cacheDictionaryEntry(_ entry: CachedDictionaryEntry) {
        let insert = dictionaryTable.insert(
            or: .replace,
            dictWord <- entry.word,
            dictDefinition <- entry.definition,
            dictPartOfSpeech <- entry.partOfSpeech,
            dictExample <- entry.example,
            dictEtymology <- entry.etymology,
            dictPhonetic <- entry.phonetic,
            dictAudioUrl <- entry.audioUrl,
            dictSynonyms <- entry.synonyms,
            dictAntonyms <- entry.antonyms,
            dictCachedAt <- entry.cachedAt
        )

        do {
            try db?.run(insert)
            print("Cached dictionary entry for: \(entry.word)")
        } catch {
            print("Failed to cache dictionary entry: \(error)")
        }
    }

    func getCachedDictionaryEntry(for word: String) -> CachedDictionaryEntry? {
        do {
            guard let db = db else { return nil }
            let query = dictionaryTable.filter(dictWord == word.lowercased())

            if let row = try db.pluck(query) {
                return CachedDictionaryEntry(
                    word: row[dictWord],
                    definition: row[dictDefinition],
                    partOfSpeech: row[dictPartOfSpeech],
                    example: row[dictExample],
                    etymology: row[dictEtymology],
                    phonetic: row[dictPhonetic],
                    audioUrl: row[dictAudioUrl],
                    synonyms: row[dictSynonyms],
                    antonyms: row[dictAntonyms],
                    cachedAt: row[dictCachedAt]
                )
            }
            return nil
        } catch {
            print("Failed to get cached dictionary entry: \(error)")
            return nil
        }
    }

    // MARK: - Collections Methods

    private func createCollectionsTables() {
        // Collections table
        let createCollections = collectionsTable.create(ifNotExists: true) { table in
            table.column(collId, primaryKey: .autoincrement)
            table.column(collName)
            table.column(collDescription, defaultValue: "")
            table.column(collCreatedAt)
            table.column(collIsSystem, defaultValue: false)
        }

        // Collection words junction table
        let createCollectionWords = collectionWordsTable.create(ifNotExists: true) { table in
            table.column(cwCollectionId)
            table.column(cwWord)
            table.column(cwAddedAt)
            table.primaryKey(cwCollectionId, cwWord)
        }

        do {
            try db?.run(createCollections)
            try db?.run(createCollectionWords)
            print("Collections tables created or already exist.")
        } catch {
            print("Failed to create collections tables: \(error)")
        }
    }

    private func createDefaultCollections() {
        let favoritesExists = UserDefaults.standard.bool(forKey: "favoritesCollectionCreated")
        if !favoritesExists {
            createCollection(name: "Favorites", description: "Your favorite words", isSystem: true)
            UserDefaults.standard.set(true, forKey: "favoritesCollectionCreated")
        }
    }

    func createCollection(name: String, description: String, isSystem: Bool = false) -> Int64? {
        let insert = collectionsTable.insert(
            collName <- name,
            collDescription <- description,
            collCreatedAt <- Date(),
            collIsSystem <- isSystem
        )

        do {
            let rowId = try db?.run(insert)
            print("Created collection: \(name)")
            return rowId
        } catch {
            print("Failed to create collection: \(error)")
            return nil
        }
    }

    func fetchAllCollections() -> [WordCollection] {
        do {
            guard let db = db else { return [] }
            var collections: [WordCollection] = []

            for row in try db.prepare(collectionsTable) {
                let collectionId = row[collId]
                let words = fetchWordsInCollection(collectionId: collectionId)

                collections.append(WordCollection(
                    id: collectionId,
                    name: row[collName],
                    description: row[collDescription],
                    createdAt: row[collCreatedAt],
                    words: words,
                    isSystem: row[collIsSystem]
                ))
            }
            return collections
        } catch {
            print("Failed to fetch collections: \(error)")
            return []
        }
    }

    func fetchWordsInCollection(collectionId: Int64) -> [String] {
        do {
            guard let db = db else { return [] }
            let query = collectionWordsTable.filter(cwCollectionId == collectionId)
            return try db.prepare(query).map { $0[cwWord] }
        } catch {
            print("Failed to fetch words in collection: \(error)")
            return []
        }
    }

    func addWordToCollection(word: String, collectionId: Int64) {
        let insert = collectionWordsTable.insert(
            or: .ignore,
            cwCollectionId <- collectionId,
            cwWord <- word.lowercased(),
            cwAddedAt <- Date()
        )

        do {
            try db?.run(insert)
            print("Added \(word) to collection \(collectionId)")
        } catch {
            print("Failed to add word to collection: \(error)")
        }
    }

    func removeWordFromCollection(word: String, collectionId: Int64) {
        let query = collectionWordsTable.filter(cwCollectionId == collectionId && cwWord == word.lowercased())

        do {
            try db?.run(query.delete())
            print("Removed \(word) from collection \(collectionId)")
        } catch {
            print("Failed to remove word from collection: \(error)")
        }
    }

    func deleteCollection(collectionId: Int64) {
        do {
            // Delete all words in collection first
            let wordsQuery = collectionWordsTable.filter(cwCollectionId == collectionId)
            try db?.run(wordsQuery.delete())

            // Delete collection
            let collQuery = collectionsTable.filter(collId == collectionId)
            try db?.run(collQuery.delete())

            print("Deleted collection \(collectionId)")
        } catch {
            print("Failed to delete collection: \(error)")
        }
    }

    func getFavoritesCollection() -> WordCollection? {
        do {
            guard let db = db else { return nil }
            let query = collectionsTable.filter(collIsSystem == true && collName == "Favorites")

            if let row = try db.pluck(query) {
                let collectionId = row[collId]
                let words = fetchWordsInCollection(collectionId: collectionId)

                return WordCollection(
                    id: collectionId,
                    name: row[collName],
                    description: row[collDescription],
                    createdAt: row[collCreatedAt],
                    words: words,
                    isSystem: row[collIsSystem]
                )
            }
            return nil
        } catch {
            print("Failed to get favorites collection: \(error)")
            return nil
        }
    }

    // MARK: - Flashcards Methods

    private func createFlashcardsTable() {
        let createTable = flashcardsTable.create(ifNotExists: true) { table in
            table.column(fcWord, primaryKey: true)
            table.column(fcLastReviewed)
            table.column(fcNextReview)
            table.column(fcEaseFactor, defaultValue: 2.5)
            table.column(fcInterval, defaultValue: 1)
            table.column(fcRepetitions, defaultValue: 0)
        }

        do {
            try db?.run(createTable)
            print("Flashcards table created or already exists.")
        } catch {
            print("Failed to create flashcards table: \(error)")
        }
    }

    func saveFlashcard(_ flashcard: Flashcard) {
        let insert = flashcardsTable.insert(
            or: .replace,
            fcWord <- flashcard.word.lowercased(),
            fcLastReviewed <- flashcard.lastReviewed,
            fcNextReview <- flashcard.nextReview,
            fcEaseFactor <- flashcard.easeFactor,
            fcInterval <- Int64(flashcard.interval),
            fcRepetitions <- Int64(flashcard.repetitions)
        )

        do {
            try db?.run(insert)
            print("Saved flashcard for: \(flashcard.word)")
        } catch {
            print("Failed to save flashcard: \(error)")
        }
    }

    func fetchFlashcard(for word: String) -> Flashcard? {
        do {
            guard let db = db else { return nil }
            let query = flashcardsTable.filter(fcWord == word.lowercased())

            if let row = try db.pluck(query) {
                var flashcard = Flashcard(word: row[fcWord])
                flashcard.lastReviewed = row[fcLastReviewed]
                flashcard.nextReview = row[fcNextReview]
                flashcard.easeFactor = row[fcEaseFactor]
                flashcard.interval = Int(row[fcInterval])
                flashcard.repetitions = Int(row[fcRepetitions])
                return flashcard
            }
            return nil
        } catch {
            print("Failed to fetch flashcard: \(error)")
            return nil
        }
    }

    func fetchDueFlashcards(limit: Int = 20) -> [Flashcard] {
        do {
            guard let db = db else { return [] }
            let now = Date()
            let query = flashcardsTable.filter(fcNextReview <= now).limit(limit)

            var flashcards: [Flashcard] = []
            for row in try db.prepare(query) {
                var flashcard = Flashcard(word: row[fcWord])
                flashcard.lastReviewed = row[fcLastReviewed]
                flashcard.nextReview = row[fcNextReview]
                flashcard.easeFactor = row[fcEaseFactor]
                flashcard.interval = Int(row[fcInterval])
                flashcard.repetitions = Int(row[fcRepetitions])
                flashcards.append(flashcard)
            }
            return flashcards
        } catch {
            print("Failed to fetch due flashcards: \(error)")
            return []
        }
    }

    // MARK: - Quiz History Methods

    private func createQuizHistoryTable() {
        let createTable = quizHistoryTable.create(ifNotExists: true) { table in
            table.column(qhId, primaryKey: .autoincrement)
            table.column(qhWord)
            table.column(qhCorrect)
            table.column(qhTimestamp)
            table.column(qhQuizType)
        }

        do {
            try db?.run(createTable)
            print("Quiz history table created or already exists.")
        } catch {
            print("Failed to create quiz history table: \(error)")
        }
    }

    func saveQuizResult(_ result: QuizResult) {
        let insert = quizHistoryTable.insert(
            qhWord <- result.word.lowercased(),
            qhCorrect <- result.correct,
            qhTimestamp <- result.timestamp,
            qhQuizType <- result.quizType.rawValue
        )

        do {
            try db?.run(insert)
            print("Saved quiz result for: \(result.word)")
        } catch {
            print("Failed to save quiz result: \(error)")
        }
    }

    func fetchQuizHistory(limit: Int = 100) -> [QuizResult] {
        do {
            guard let db = db else { return [] }
            let query = quizHistoryTable.order(qhTimestamp.desc).limit(limit)

            var results: [QuizResult] = []
            for row in try db.prepare(query) {
                if let quizType = QuizType(rawValue: row[qhQuizType]) {
                    results.append(QuizResult(
                        word: row[qhWord],
                        correct: row[qhCorrect],
                        timestamp: row[qhTimestamp],
                        quizType: quizType
                    ))
                }
            }
            return results
        } catch {
            print("Failed to fetch quiz history: \(error)")
            return []
        }
    }

    func getQuizStats() -> (total: Int, correct: Int, accuracy: Double) {
        do {
            guard let db = db else { return (0, 0, 0.0) }
            let total = try db.scalar(quizHistoryTable.count)
            let correct = try db.scalar(quizHistoryTable.filter(qhCorrect == true).count)
            let accuracy = total > 0 ? Double(correct) / Double(total) : 0.0
            return (total, correct, accuracy)
        } catch {
            print("Failed to get quiz stats: \(error)")
            return (0, 0, 0.0)
        }
    }

    // MARK: - Game Scores Methods

    private func createGameScoresTable() {
        let createTable = gameScoresTable.create(ifNotExists: true) { table in
            table.column(gsId, primaryKey: .autoincrement)
            table.column(gsGameType)
            table.column(gsScore)
            table.column(gsTimestamp)
            table.column(gsDetails, defaultValue: "")
        }

        do {
            try db?.run(createTable)
            print("Game scores table created or already exists.")
        } catch {
            print("Failed to create game scores table: \(error)")
        }
    }

    func saveGameScore(_ score: GameScore) {
        let insert = gameScoresTable.insert(
            gsGameType <- score.gameType.rawValue,
            gsScore <- Int64(score.score),
            gsTimestamp <- score.timestamp,
            gsDetails <- score.details
        )

        do {
            try db?.run(insert)
            print("Saved game score: \(score.score)")
        } catch {
            print("Failed to save game score: \(error)")
        }
    }

    func fetchHighScores(gameType: GameType, limit: Int = 10) -> [GameScore] {
        do {
            guard let db = db else { return [] }
            let query = gameScoresTable
                .filter(gsGameType == gameType.rawValue)
                .order(gsScore.desc, gsTimestamp.desc)
                .limit(limit)

            var scores: [GameScore] = []
            for row in try db.prepare(query) {
                if let type = GameType(rawValue: row[gsGameType]) {
                    scores.append(GameScore(
                        gameType: type,
                        score: Int(row[gsScore]),
                        timestamp: row[gsTimestamp],
                        details: row[gsDetails]
                    ))
                }
            }
            return scores
        } catch {
            print("Failed to fetch high scores: \(error)")
            return []
        }
    }

    // MARK: - Advanced Search Methods

    func searchWords(pattern: String) -> [String] {
        do {
            guard let db = db else { return [] }
            // Convert pattern: ? -> _, * -> %
            let sqlPattern = pattern
                .replacingOccurrences(of: "?", with: "_")
                .replacingOccurrences(of: "*", with: "%")

            let query = wordsTable.filter(word.like(sqlPattern)).limit(100)
            return try db.prepare(query).map { $0[word] }
        } catch {
            print("Failed to search words: \(error)")
            return []
        }
    }

    func searchWordsByLength(length: Int) -> [String] {
        do {
            guard let db = db else { return [] }
            let query = wordsTable.filter(word.length == length).limit(100)
            return try db.prepare(query).map { $0[word] }
        } catch {
            print("Failed to search words by length: \(error)")
            return []
        }
    }

    func searchWordsContaining(substring: String) -> [String] {
        do {
            guard let db = db else { return [] }
            let query = wordsTable.filter(word.like("%\(substring.lowercased())%")).limit(100)
            return try db.prepare(query).map { $0[word] }
        } catch {
            print("Failed to search words containing substring: \(error)")
            return []
        }
    }

    func searchWordsStartingWith(prefix: String) -> [String] {
        do {
            guard let db = db else { return [] }
            let query = wordsTable.filter(word.like("\(prefix.lowercased())%")).limit(100)
            return try db.prepare(query).map { $0[word] }
        } catch {
            print("Failed to search words starting with prefix: \(error)")
            return []
        }
    }

    func searchWordsEndingWith(suffix: String) -> [String] {
        do {
            guard let db = db else { return [] }
            let query = wordsTable.filter(word.like("%\(suffix.lowercased())")).limit(100)
            return try db.prepare(query).map { $0[word] }
        } catch {
            print("Failed to search words ending with suffix: \(error)")
            return []
        }
    }

    func getAllWords() -> [String] {
        do {
            guard let db = db else { return [] }
            return try db.prepare(wordsTable.select(word)).map { $0[word] }
        } catch {
            print("Failed to get all words: \(error)")
            return []
        }
    }
}

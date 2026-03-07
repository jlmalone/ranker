
// ranker/Ranker/DatabaseManager.swift

import Foundation
import SQLite

class DatabaseManager {
    private var db: Connection?
    private var associationsDb: Connection?

    // MARK: - fullwords table
    let wordsTable = Table("fullwords")
    let id = SQLite.Expression<Int64>("id")
    let word = SQLite.Expression<String>("word")
    let rank = SQLite.Expression<Double>("rank")
    let notable = SQLite.Expression<Bool>("notable")
    let reviewed = SQLite.Expression<Bool>("reviewed")
    let eloScore = SQLite.Expression<Double>("elo_score")
    let source = SQLite.Expression<String?>("source")

    // MARK: - memory_dumps table
    let memoryDumpsTable = Table("memory_dumps")
    let dump_id = SQLite.Expression<Int64>("id")
    let dump_prompt = SQLite.Expression<String>("prompt")
    let dump_content = SQLite.Expression<String>("content")
    let dump_created_at = SQLite.Expression<String>("created_at")

    // MARK: - elo_comparisons table
    let eloComparisonsTable = Table("elo_comparisons")
    let elo_id = SQLite.Expression<Int64>("id")
    let elo_word_a_id = SQLite.Expression<Int64>("word_a_id")
    let elo_word_b_id = SQLite.Expression<Int64>("word_b_id")
    let elo_winner_id = SQLite.Expression<Int64>("winner_id")
    let elo_created_at = SQLite.Expression<String>("created_at")

    // MARK: - pattern_rankings table
    let patternRankingsTable = Table("pattern_rankings")
    let pattern_id = SQLite.Expression<Int64>("id")
    let pattern_name = SQLite.Expression<String>("pattern")
    let pattern_example = SQLite.Expression<String>("example")
    let pattern_confidence = SQLite.Expression<Double>("confidence")
    let pattern_created_at = SQLite.Expression<String>("created_at")

    // MARK: - association_chains table
    let associationChainsTable = Table("association_chains")
    let chain_id_pk = SQLite.Expression<Int64>("id")
    let chain_from_word = SQLite.Expression<String>("from_word")
    let chain_to_word = SQLite.Expression<String>("to_word")
    let chain_label = SQLite.Expression<String>("label")
    let chain_id = SQLite.Expression<String>("chain_id")
    let chain_position = SQLite.Expression<Int64>("position")
    let chain_created_at = SQLite.Expression<String>("created_at")

    // MARK: - word_associations table (in associations_db)
    let associationsTable = Table("word_associations")
    let assoc_id = SQLite.Expression<Int64>("id")
    let assoc_main_word_id = SQLite.Expression<Int64>("main_word_id")
    let assoc_text = SQLite.Expression<String>("associated_text")
    let assoc_is_starred = SQLite.Expression<Bool>("is_starred")
    let assoc_created_at = SQLite.Expression<Date>("created_at")

    // MARK: - audio_recordings table (in associations_db)
    let recordingsTable = Table("audio_recordings")
    let rec_id = SQLite.Expression<Int64>("id")
    let rec_main_word_id = SQLite.Expression<Int64>("main_word_id")
    let rec_audio_filename = SQLite.Expression<String>("audio_filename")
    let rec_transcript_text = SQLite.Expression<String?>("transcript_text")
    let rec_is_starred = SQLite.Expression<Bool>("is_starred")
    let rec_created_at = SQLite.Expression<Date>("created_at")

    init() {
        setupDatabase()
        setupAssociationsDatabase()

        createWordsTable()
        createMemoryDumpsTable()
        createEloComparisonsTable()
        createPatternRankingsTable()
        createAssociationChainsTable()
        migrateWordsTableColumns()

        createAssociationsTable()
        createRecordingsTable()
    }

    // MARK: - Database Setup

    func databasePath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("db_full_words.sqlite3").path
    }

    private func setupDatabase() {
        do {
            let path = databasePath()

            // On first launch, copy bundled database with 2.95M words
            if !FileManager.default.fileExists(atPath: path) {
                if let bundledPath = Bundle.main.path(forResource: "db_full_words_bundled", ofType: "sqlite3") {
                    try FileManager.default.copyItem(atPath: bundledPath, toPath: path)
                    print("Copied bundled database with 2.95M words to Documents")
                }
            }

            db = try Connection(path)
        } catch {
            print("Unable to set up database: \(error)")
        }
    }

    private func setupAssociationsDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            associationsDb = try Connection("\(path)/associations_db.sqlite3")
        } catch {
            print("Unable to set up associations database: \(error)")
            associationsDb = nil
        }
    }

    // MARK: - Table Creation

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
        } catch {
            print("Failed to create fullwords table: \(error)")
        }
    }

    private func migrateWordsTableColumns() {
        guard let db = db else { return }
        // Add elo_score column if not present
        do {
            try db.run("ALTER TABLE fullwords ADD COLUMN elo_score REAL DEFAULT 1200.0")
        } catch {
            // Column already exists, ignore
        }
        // Add source column if not present
        do {
            try db.run("ALTER TABLE fullwords ADD COLUMN source TEXT")
        } catch {
            // Column already exists, ignore
        }
    }

    private func createMemoryDumpsTable() {
        guard let db = db else { return }
        let createTable = memoryDumpsTable.create(ifNotExists: true) { table in
            table.column(dump_id, primaryKey: .autoincrement)
            table.column(dump_prompt)
            table.column(dump_content)
            table.column(dump_created_at)
        }
        do {
            try db.run(createTable)
        } catch {
            print("Failed to create memory_dumps table: \(error)")
        }
    }

    private func createEloComparisonsTable() {
        guard let db = db else { return }
        let createTable = eloComparisonsTable.create(ifNotExists: true) { table in
            table.column(elo_id, primaryKey: .autoincrement)
            table.column(elo_word_a_id)
            table.column(elo_word_b_id)
            table.column(elo_winner_id)
            table.column(elo_created_at)
        }
        do {
            try db.run(createTable)
        } catch {
            print("Failed to create elo_comparisons table: \(error)")
        }
    }

    private func createPatternRankingsTable() {
        guard let db = db else { return }
        let createTable = patternRankingsTable.create(ifNotExists: true) { table in
            table.column(pattern_id, primaryKey: .autoincrement)
            table.column(pattern_name)
            table.column(pattern_example)
            table.column(pattern_confidence)
            table.column(pattern_created_at)
        }
        do {
            try db.run(createTable)
        } catch {
            print("Failed to create pattern_rankings table: \(error)")
        }
    }

    private func createAssociationChainsTable() {
        guard let db = db else { return }
        let createTable = associationChainsTable.create(ifNotExists: true) { table in
            table.column(chain_id_pk, primaryKey: .autoincrement)
            table.column(chain_from_word)
            table.column(chain_to_word)
            table.column(chain_label, defaultValue: "reminds me of")
            table.column(chain_id)
            table.column(chain_position)
            table.column(chain_created_at)
        }
        do {
            try db.run(createTable)
        } catch {
            print("Failed to create association_chains table: \(error)")
        }
    }

    private func createAssociationsTable() {
        guard let assocDB = self.associationsDb else { return }
        let createTable = associationsTable.create(ifNotExists: true) { table in
            table.column(assoc_id, primaryKey: .autoincrement)
            table.column(assoc_main_word_id)
            table.column(assoc_text)
            table.column(assoc_is_starred)
            table.column(assoc_created_at)
        }
        do {
            try assocDB.run(createTable)
        } catch {
            print("Failed to create associations table: \(error)")
        }
    }

    private func createRecordingsTable() {
        guard let assocDB = self.associationsDb else { return }
        let createTable = recordingsTable.create(ifNotExists: true) { table in
            table.column(rec_id, primaryKey: .autoincrement)
            table.column(rec_main_word_id)
            table.column(rec_audio_filename)
            table.column(rec_transcript_text)
            table.column(rec_is_starred)
            table.column(rec_created_at)
        }
        do {
            try assocDB.run(createTable)
        } catch {
            print("Failed to create recordings table: \(error)")
        }
    }

    // MARK: - Memory Dumps (Mode 1)

    func saveMemoryDump(prompt: String, content: String) {
        guard let db = db else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        let insert = memoryDumpsTable.insert(
            dump_prompt <- prompt,
            dump_content <- content,
            dump_created_at <- now
        )
        do {
            try db.run(insert)
        } catch {
            print("Failed to save memory dump: \(error)")
        }
    }

    func insertWordFromDump(_ wordText: String, wordSource: String = "free_association") {
        guard let db = db else { return }
        let cleaned = wordText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleaned.isEmpty else { return }
        do {
            try db.run(wordsTable.insert(or: .ignore,
                word <- cleaned,
                rank <- 0.5,
                notable <- false,
                reviewed <- false,
                eloScore <- 1200.0,
                source <- wordSource
            ))
        } catch {
            print("Failed to insert word '\(cleaned)': \(error)")
        }
    }

    // MARK: - Elo Comparisons (Mode 2)

    func fetchPairForComparison() -> (Word, Word)? {
        guard let db = db else { return nil }
        do {
            // Get words with fewest comparisons, prefer similar Elo scores
            let allWords = try db.prepare(wordsTable.order(SQLite.Expression<Int64>.random()).limit(50))
            var words: [Word] = []
            for row in allWords {
                words.append(Word(
                    id: row[id],
                    name: row[word],
                    rank: row[rank],
                    isNotable: row[notable],
                    eloScore: row[eloScore]
                ))
            }
            guard words.count >= 2 else { return nil }

            // Count comparisons per word
            var comparisonCounts: [Int64: Int] = [:]
            for w in words {
                let count = try db.scalar(
                    eloComparisonsTable.filter(elo_word_a_id == w.id || elo_word_b_id == w.id).count
                )
                comparisonCounts[w.id] = count
            }

            // Sort by fewest comparisons
            words.sort { (comparisonCounts[$0.id] ?? 0) < (comparisonCounts[$1.id] ?? 0) }

            let wordA = words[0]
            // Find word B with similar Elo to wordA
            let remaining = words.dropFirst().sorted { abs($0.eloScore - wordA.eloScore) < abs($1.eloScore - wordA.eloScore) }
            guard let wordB = remaining.first else { return nil }

            return (wordA, wordB)
        } catch {
            print("Failed to fetch pair: \(error)")
            return nil
        }
    }

    func recordEloComparison(wordAId: Int64, wordBId: Int64, winnerId: Int64) {
        guard let db = db else { return }
        let now = ISO8601DateFormatter().string(from: Date())

        do {
            // Fetch current Elo scores
            guard let rowA = try db.pluck(wordsTable.filter(id == wordAId)),
                  let rowB = try db.pluck(wordsTable.filter(id == wordBId)) else { return }

            let eloA = rowA[eloScore]
            let eloB = rowB[eloScore]
            let K = 32.0

            let expectedA = 1.0 / (1.0 + pow(10.0, (eloB - eloA) / 400.0))
            let expectedB = 1.0 / (1.0 + pow(10.0, (eloA - eloB) / 400.0))

            let resultA = winnerId == wordAId ? 1.0 : 0.0
            let resultB = winnerId == wordBId ? 1.0 : 0.0

            let newEloA = eloA + K * (resultA - expectedA)
            let newEloB = eloB + K * (resultB - expectedB)

            // Update Elo scores
            try db.run(wordsTable.filter(id == wordAId).update(eloScore <- newEloA))
            try db.run(wordsTable.filter(id == wordBId).update(eloScore <- newEloB))

            // Record comparison
            try db.run(eloComparisonsTable.insert(
                elo_word_a_id <- wordAId,
                elo_word_b_id <- wordBId,
                elo_winner_id <- winnerId,
                elo_created_at <- now
            ))
        } catch {
            print("Failed to record Elo comparison: \(error)")
        }
    }

    func countEloComparisons() -> Int {
        guard let db = db else { return 0 }
        do {
            return try db.scalar(eloComparisonsTable.count)
        } catch {
            return 0
        }
    }

    func fetchTopWords(limit: Int = 5) -> [Word] {
        guard let db = db else { return [] }
        do {
            let query = wordsTable.order(eloScore.desc).limit(limit)
            return try db.prepare(query).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    // MARK: - Pattern Rankings (Mode 3)

    func savePatternRankings(_ patterns: [(pattern: String, example: String, confidence: Double)]) {
        guard let db = db else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        do {
            // Clear existing rankings and re-save
            try db.run(patternRankingsTable.delete())
            for p in patterns {
                try db.run(patternRankingsTable.insert(
                    pattern_name <- p.pattern,
                    pattern_example <- p.example,
                    pattern_confidence <- p.confidence,
                    pattern_created_at <- now
                ))
            }
        } catch {
            print("Failed to save pattern rankings: \(error)")
        }
    }

    func fetchPatternRankings() -> [(id: Int64, pattern: String, example: String, confidence: Double)] {
        guard let db = db else { return [] }
        do {
            return try db.prepare(patternRankingsTable.order(pattern_confidence.desc)).map { row in
                (id: row[pattern_id], pattern: row[pattern_name], example: row[pattern_example], confidence: row[pattern_confidence])
            }
        } catch {
            return []
        }
    }

    // MARK: - Association Chains (Mode 5)

    func addChainLink(fromWord: String, toWord: String, label: String = "reminds me of", chainUUID: String, position: Int) {
        guard let db = db else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        do {
            try db.run(associationChainsTable.insert(
                chain_from_word <- fromWord,
                chain_to_word <- toWord,
                chain_label <- label,
                chain_id <- chainUUID,
                chain_position <- Int64(position),
                chain_created_at <- now
            ))
            // Auto-add both words to fullwords
            insertWordFromDump(fromWord, wordSource: "association_chain")
            insertWordFromDump(toWord, wordSource: "association_chain")
        } catch {
            print("Failed to add chain link: \(error)")
        }
    }

    func fetchChain(chainUUID: String) -> [(from: String, to: String, label: String)] {
        guard let db = db else { return [] }
        do {
            let query = associationChainsTable.filter(chain_id == chainUUID).order(chain_position.asc)
            return try db.prepare(query).map { row in
                (from: row[chain_from_word], to: row[chain_to_word], label: row[chain_label])
            }
        } catch {
            return []
        }
    }

    func fetchAllChainIds() -> [String] {
        guard let db = db else { return [] }
        do {
            let query = associationChainsTable.select(distinct: chain_id)
            return try db.prepare(query).map { $0[chain_id] }
        } catch {
            return []
        }
    }

    // MARK: - Word Operations (existing + enhanced)

    func fetchUserAddedWords(batchSize: Int, offset: Int = 0) -> [Word] {
        guard let db = db else { return [] }
        do {
            let query = wordsTable
                .filter(source != "wikipedia+wiktionary" && source != nil)
                .order(rank.desc)
                .limit(batchSize, offset: offset)
            return try db.prepare(query).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    func countUserAddedWords() -> Int {
        guard let db = db else { return 0 }
        do {
            return try db.scalar(wordsTable.filter(source != "wikipedia+wiktionary" && source != nil).count)
        } catch { return 0 }
    }

    func fetchWordsWithNotes(batchSize: Int, offset: Int = 0) -> [Word] {
        guard let db = db, let assocDB = associationsDb else { return [] }
        do {
            // Get word IDs that have associations
            let wordIds = try assocDB.prepare(
                associationsTable.select(distinct: assoc_main_word_id)
            ).map { $0[assoc_main_word_id] }

            guard !wordIds.isEmpty else { return [] }

            let query = wordsTable
                .filter(wordIds.contains(id))
                .order(rank.desc)
                .limit(batchSize, offset: offset)
            return try db.prepare(query).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    func countWordsWithNotes() -> Int {
        guard let assocDB = associationsDb else { return 0 }
        do {
            return try assocDB.scalar(associationsTable.select(assoc_main_word_id.distinct.count))
        } catch { return 0 }
    }

    func fetchNotableWords(batchSize: Int, offset: Int = 0) -> [Word] {
        guard let db = db else { return [] }
        do {
            let query = wordsTable
                .filter(notable == true)
                .order(rank.desc)
                .limit(batchSize, offset: offset)
            return try db.prepare(query).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    func countNotableWords() -> Int {
        guard let db = db else { return 0 }
        do { return try db.scalar(wordsTable.filter(notable == true).count) }
        catch { return 0 }
    }

    func fetchReviewedWords(batchSize: Int, offset: Int = 0) -> [Word] {
        guard let db = db else { return [] }
        do {
            let query = wordsTable
                .filter(reviewed == true)
                .order(rank.desc)
                .limit(batchSize, offset: offset)
            return try db.prepare(query).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
        guard let db = db else { return [] }
        do {
            let query = wordsTable.filter(reviewed == false).order(SQLite.Expression<Int64>.random()).limit(batchSize)
            return try db.prepare(query).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }

    func fetchAllWords() -> [Word] {
        guard let db = db else { return [] }
        do {
            return try db.prepare(wordsTable.order(eloScore.desc)).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    func updateWord(word: Word) {
        let wordRow = wordsTable.filter(id == word.id)
        do {
            // Any slider movement away from 0.5 default = reviewed
            let isReviewed = abs(word.rank - 0.5) > 0.001
            try db?.run(wordRow.update(self.rank <- word.rank, self.notable <- word.isNotable, self.reviewed <- isReviewed))
        } catch {
            print("Update failed for \(word.name): \(error)")
        }
    }

    func countReviewedWords() -> Int {
        do { return try db?.scalar(wordsTable.filter(reviewed == true).count) ?? 0 }
        catch { return 0 }
    }

    func countUnreviewedWords() -> Int {
        do { return try db?.scalar(wordsTable.filter(reviewed == false).count) ?? 0 }
        catch { return 0 }
    }

    func countTotalWords() -> Int {
        do { return try db?.scalar(wordsTable.count) ?? 0 }
        catch { return 0 }
    }

    func searchWords(query: String) -> [Word] {
        guard let db = db else { return [] }
        do {
            let queryPattern = "%\(query.lowercased())%"
            let filteredWords = wordsTable.filter(word.like(queryPattern)).limit(200)
            return try db.prepare(filteredWords).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    func searchWordsPaginated(query: String, batchSize: Int, offset: Int, unrankedOnly: Bool = false) -> [Word] {
        guard let db = db else { return [] }
        do {
            let queryPattern = "%\(query.lowercased())%"
            var filteredWords = wordsTable.filter(word.like(queryPattern))
            if unrankedOnly {
                filteredWords = filteredWords.filter(rank > 0.499 && rank < 0.501)
            }
            filteredWords = filteredWords.order(word.asc).limit(batchSize, offset: offset)
            return try db.prepare(filteredWords).map { row in
                Word(id: row[id], name: row[word], rank: row[rank], isNotable: row[notable], eloScore: row[eloScore])
            }
        } catch {
            return []
        }
    }

    func countSearchResults(query: String, unrankedOnly: Bool = false) -> Int {
        guard let db = db else { return 0 }
        do {
            let queryPattern = "%\(query.lowercased())%"
            var filter = wordsTable.filter(word.like(queryPattern))
            if unrankedOnly {
                filter = filter.filter(rank > 0.499 && rank < 0.501)
            }
            return try db.scalar(filter.count)
        } catch {
            return 0
        }
    }

    // MARK: - Complexity Estimation

    /// Returns [wordLength: count] for all words
    func wordLengthDistribution() -> [Int: Int] {
        guard let db = db else { return [:] }
        do {
            var dist: [Int: Int] = [:]
            let rows = try db.prepare("SELECT LENGTH(word) as len, COUNT(*) as cnt FROM fullwords GROUP BY LENGTH(word)")
            for row in rows {
                let len = Int(row[0] as! Int64)
                let cnt = Int(row[1] as! Int64)
                dist[len] = cnt
            }
            return dist
        } catch { return [:] }
    }

    /// Returns [wordLength: count] for active words (rank >= 0.06)
    func activeWordLengthDistribution() -> [Int: Int] {
        guard let db = db else { return [:] }
        do {
            var dist: [Int: Int] = [:]
            let rows = try db.prepare("SELECT LENGTH(word) as len, COUNT(*) as cnt FROM fullwords WHERE rank >= 0.06 GROUP BY LENGTH(word)")
            for row in rows {
                let len = Int(row[0] as! Int64)
                let cnt = Int(row[1] as! Int64)
                dist[len] = cnt
            }
            return dist
        } catch { return [:] }
    }

    func countActiveWords() -> Int {
        guard let db = db else { return 0 }
        do { return try db.scalar(wordsTable.filter(rank >= 0.06).count) }
        catch { return 0 }
    }

    // MARK: - Associations & Recordings

    func addWordAssociation(mainWordId: Int64, text: String, isStarred: Bool) throws {
        guard let assocDB = self.associationsDb else {
            throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Associations database not initialized"])
        }
        let insert = associationsTable.insert(
            assoc_main_word_id <- mainWordId,
            assoc_text <- text,
            assoc_is_starred <- isStarred,
            assoc_created_at <- Date()
        )
        try assocDB.run(insert)
    }

    func saveAudioRecording(mainWordId: Int64, audioFilename: String, transcript: String?, isStarred: Bool) throws {
        guard let assocDB = self.associationsDb else {
            throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Associations database not initialized"])
        }
        let insert = recordingsTable.insert(
            rec_main_word_id <- mainWordId,
            rec_audio_filename <- audioFilename,
            rec_transcript_text <- transcript,
            rec_is_starred <- isStarred,
            rec_created_at <- Date()
        )
        try assocDB.run(insert)
    }

    // MARK: - Fetch Associations & Recordings (for WordCaptureSheet)

    func fetchAssociations(forWordId wordId: Int64) -> [(text: String, date: String)] {
        guard let assocDB = self.associationsDb else { return [] }
        do {
            let query = associationsTable.filter(assoc_main_word_id == wordId).order(assoc_created_at.desc)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            return try assocDB.prepare(query).map { row in
                (text: row[assoc_text], date: dateFormatter.string(from: row[assoc_created_at]))
            }
        } catch {
            print("Failed to fetch associations: \(error)")
            return []
        }
    }

    func fetchRecordings(forWordId wordId: Int64) -> [(filename: String, transcript: String?, date: String)] {
        guard let assocDB = self.associationsDb else { return [] }
        do {
            let query = recordingsTable.filter(rec_main_word_id == wordId).order(rec_created_at.desc)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            return try assocDB.prepare(query).map { row in
                (filename: row[rec_audio_filename], transcript: row[rec_transcript_text], date: dateFormatter.string(from: row[rec_created_at]))
            }
        } catch {
            print("Failed to fetch recordings: \(error)")
            return []
        }
    }

    // MARK: - Export (P7)

    func exportToJSON() -> Data? {
        guard let db = db else { return nil }
        do {
            var seeds: [[String: Any]] = []
            // Sort by slider rank (user sentiment) as primary, Elo as secondary
            let query = wordsTable.order(rank.desc, eloScore.desc)
            for row in try db.prepare(query) {
                let sliderRank = row[rank]
                let elo = row[eloScore]
                // Priority from slider rank: user's direct judgment is the source of truth
                let priority: Int = sliderRank > 0.7 ? 3 : (sliderRank > 0.4 ? 2 : 1)
                seeds.append([
                    "word": row[word],
                    "rank": sliderRank,
                    "elo_score": elo,
                    "priority": priority,
                    "source": row[source] ?? "free_association",
                    "reviewed": row[reviewed],
                    "notes": ""
                ])
            }

            var patterns: [[String: Any]] = []
            for row in try db.prepare(patternRankingsTable.order(pattern_confidence.desc)) {
                patterns.append([
                    "pattern": row[pattern_name],
                    "example": row[pattern_example],
                    "confidence": row[pattern_confidence]
                ])
            }

            let exportData: [String: Any] = [
                "version": 1,
                "exported_from": "ranker",
                "exported_at": ISO8601DateFormatter().string(from: Date()),
                "seeds": seeds,
                "patterns": patterns
            ]

            return try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
}

import Foundation
import SQLite

class DatabaseManager {
    private var db: Connection?
    
    let wordsTable = Table("words")
    let id = Expression<Int64>("id")
    let word = Expression<String>("word")
    let rank = Expression<Double>("rank")
    let notable = Expression<Bool>("notable")
    let reviewed = Expression<Bool>("reviewed")
    
    
    // New word association database
    private var assocDb: Connection?
    let associationsTable = Table("associations")
    let assocId = Expression<Int64>("assocId")
    let assocWord = Expression<String>("assocWord")
    let assocRank = Expression<Double>("assocRank")
    let assocNotable = Expression<Bool>("assocNotable")
    
    let recordingsTable = Table("recordings")
    let recordingId = Expression<String>("recordingId")
    let assocRecordingWord = Expression<String>("assocRecordingWord")
    let transcription = Expression<String>("transcription")
    

    let associationText = Expression<String>("associationText")
    let audioFile = Expression<String>("audioFile") // Add this line
    let isStarred = Expression<Bool>("isStarred") // Add this line
    
    
    init() {
        setupDatabase()
       
        populateInitialDataIfNeeded()
        createAssociationsDatabase()
       
        createTables()
        populateInitialDataIfNeeded()
    }

    private func createTables() {
        createWordsTable()
        createAssociationsTable() // Include this line
        createRecordingsTable() // Include this line
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
    
    
    // MARK: - New Association Database Methods
    private func createAssociationsDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            assocDb = try Connection("\(path)/assoc.sqlite3")
        } catch {
            print("Unable to set up association database: \(error)")
        }
    }

    private func createAssociationsTable() {
        let createTable = associationsTable.create(ifNotExists: true) { table in
            table.column(assocId, primaryKey: .autoincrement)
            table.column(assocWord, unique: true)
            table.column(assocRank, defaultValue: 0.5)
            table.column(assocNotable, defaultValue: false)
        }
        
        do {
            try assocDb?.run(createTable)
            print("Created associations table or already exists.")
        } catch {
            print("Failed to create associations table: \(error)")
        }
    }

    private func createRecordingsTable() {
        let createTable = recordingsTable.create(ifNotExists: true) { table in
            table.column(recordingId, primaryKey: true)
            table.column(assocRecordingWord)
            table.column(transcription)
            table.column(audioFile)
        }
        
        do {
            try assocDb?.run(createTable)
            print("Created recordings table or already exists.")
        } catch {
            print("Failed to create recordings table: \(error)")
        }
    }
    
    // Fetch words for association ranking
    func fetchUnrankedAssociations(batchSize: Int) -> [Word] {
        do {
            guard let assocDb = assocDb else { return [] }
            let query = associationsTable.order(assocId).limit(batchSize)
            let rows = try assocDb.prepare(query)
            var result: [Word] = []
            for row in rows {
                let wordItem = Word(
                    id: row[assocId],
                    name: row[assocWord],
                    rank: row[assocRank],
                    isNotable: row[assocNotable]
                )
                result.append(wordItem)
            }
            return result
        } catch {
            print("Fetch unranked associations failed: \(error)")
            return []
        }
    }
    
    
    //TODO alt
//    func fetchUnrankedAssociations(batchSize: Int) -> [Word] {
//        do {
//            let query = wordsTable.filter(reviewed == false).limit(batchSize)
//            let rows = try db.prepare(query)
//            var results = [Word]()
//            for row in rows {
//                let wordItem = Word(name: row[word], rank: row[rank], isNotable: row[notable])
//                results.append(wordItem)
//            }
//            print("Fetched associations: \(results)")
//            return results
//        } catch {
//            print("Error fetching associations: \(error)")
//            return []
//        }
//    }
    
    func updateAssociation(word: Word) {
        let wordRow = associationsTable.filter(self.assocWord == word.name)
        do {
            if try assocDb?.run(wordRow.update(assocRank <- word.rank, assocNotable <- word.isNotable)) ?? 0 > 0 {
                print("Updated association for: \(word.name)")
            } else {
                print("Association word not found: \(word.name)")
            }
        } catch {
            print("Update failed for association \(word.name): \(error)")
        }
    }

//    // Store voice recording metadata
//    func saveRecordingMetadata(recordingId: String, word: String, transcription: String) {
//        do {
//            let insert = recordingsTable.insert(self.recordingId <- recordingId, self.assocRecordingWord <- word, self.transcription <- transcription)
//            try assocDb?.run(insert)
//        } catch {
//            print("Failed to save recording metadata: \(error)")
//        }
//    }
    
    // Method to add word associations
    func addWordAssociation(word: String, associationText: String, isStarred: Bool) {
        do {
            let insert = associationsTable.insert(self.word <- word, self.associationText <- associationText, self.isStarred <- isStarred)
            try db?.run(insert)
            print("Word association added successfully.")
        } catch {
            print("Failed to add word association: \(error)")
        }
    }
    
//    func saveRecordingMetadata(recordingId: String, word: String, transcription: String, audioFileName: String?, isStarred: Bool) {
//        do {
//            let insert = recordingsTable.insert(
//                self.recordingId <- recordingId,
//                self.assocRecordingWord <- word.lowercased(),
//                self.transcription <- transcription,
//                self.audioFile <- audioFileName,
//                self.isStarred <- isStarred
//            )
//            try db?.run(insert)
//        } catch {
//            print("Failed to save recording metadata: \(error)")
//        }
//    }

    
    func saveRecordingMetadata(recordingId: String, word: String, transcription: String, audioFileName: String?, isStarred: Bool) {
        do {
            let insert = recordingsTable.insert(
                self.recordingId <- recordingId,
                self.assocRecordingWord <- word.lowercased(),
                self.transcription <- transcription,
                self.audioFile <- (audioFileName ?? ""),  // Unwrapping audioFileName
                self.isStarred <- isStarred
            )
            try db?.run(insert)
        } catch {
            print("Failed to save recording metadata: \(error)")
        }
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
                    id: row[id],  // Add this line
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
//    
//    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
//        do {
//            guard let db = db else {
//                print("Database connection is nil.")
//                return []
//            }
//
//            // Use SQL's random() function directly in the order clause
//            let query = wordsTable.filter(reviewed == false).order(SQLite.Expression<Int64>.random()).limit(batchSize)
//            let rows = try db.prepare(query)
//            var result: [Word] = []
//            for row in rows {
//                let wordItem = Word(
//                    name: row[word],
//                    rank: row[rank],
//                    isNotable: row[notable]
//                )
//                result.append(wordItem)
//            }
//            return result
//        } catch {
//            print("Fetch failed: \(error)")
//            return []
//        }
//    }

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
    func searchWords(query: String) -> [Word] {
        do {
            guard let db = db else {
                print("Database connection is nil.")
                return []
            }

            let queryPattern = "%\(query.lowercased())%" // SQL LIKE pattern
            let filteredWords = wordsTable.filter(word.like(queryPattern))
            
            let rows = try db.prepare(filteredWords)
            var result: [Word] = []
            for row in rows {
                let wordItem = Word(
                    id: row[id],  // Add this line
                    name: row[word],
                    rank: row[rank],
                    isNotable: row[notable]
                )
                result.append(wordItem)
            }
            return result
        } catch {
            print("Search failed: \(error)")
            return []
        }
    }

    
    
}

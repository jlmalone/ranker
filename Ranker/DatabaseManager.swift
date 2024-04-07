//
//  DatabaseManager.swift
//  Ranker
//
//  Created by Joseph Malone on 4/5/24.
//



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
    
    init() {
        setupDatabase()
        createWordsTable()
        populateInitialDataIfNeeded()
    }
    
//    private func setupDatabase() {
//        do {
//            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
//            let dbPath = "\(path)/db.sqlite3"
//            
//            // Check if the file exists and delete it
//            if FileManager.default.fileExists(atPath: dbPath) {
//                try FileManager.default.removeItem(atPath: dbPath)
//                print("Existing database file deleted.")
//            }
//
//            db = try Connection(dbPath)
//        } catch {
//            print("Database operation failed: \(error)")
//        }
//    }
    
    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/db.sqlite3")
        } catch {
            print("Unable to set up database: \(error)")
        }
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
    
    
    
    
    
//
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
    
//    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
//        do {
//            let query = wordsTable.filter(reviewed == false).limit(batchSize)
//            guard let db = db else { return [] }
//            let rows = try db.prepare(query)
//            return rows.map { Word(name: $0[word], rank: $0[rank], isNotable: $0[reviewed]) }
//        } catch {
//            print("Fetch failed: \(error)")
//            return []
//        }
//    }

    
    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
        print("Fetch unreviewed hit")
        do {
            let query = wordsTable.filter(reviewed == false).limit(batchSize)
            guard let db = db else { return [] }
            let rows = try db.prepare(query)
            var result: [Word] = []
            for row in rows {
                let wordItem = Word(
                    name: row[word],
                    rank: row[rank],
                    isNotable: row[reviewed]
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
//        word.reviewed = true
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
}




























//
//import Foundation
//
//import SQLite
//
//class DatabaseManager {
//    private var db: Connection?
//    
//    let wordsTable = Table("words")
//    let id = Expression<Int64>("id")
//    let word = Expression<String>("word")
//    let rank = Expression<Double>("rank")
//    let reviewed = Expression<Bool>("reviewed")
//    
//    init() {
//        setupDatabase()
//        createWordsTable()
//        populateInitialData()
//    }
//    
////    func populateInitialData() {
////           // Populate with all 3-letter combinations
////           let letters = Array("abcdefghijklmnopqrstuvwxyz")
////           for first in letters {
////               for second in letters {
////                   for third in letters {
////                       let combination = "\(first)\(second)\(third)"
////                       insertWord(newWord: Word(name: combination, rank: 0.5))
////                   }
////               }
////           }
////
////           // Populate with numbers 1 to 9999 (1 to 4-digit numbers)
////           for number in 1...9999 {
////               insertWord(word: Word(name: "\(number)", rank: 0.5))
////           }
////       }
////    
////    
//    func populateInitialData() {
//        // Populate with all 3-letter combinations
//        let letters = Array("abcdefghijklmnopqrstuvwxyz")
//        for first in letters {
//            for second in letters {
//                for third in letters {
//                    let combination = "\(first)\(second)\(third)"
//                    insertWord(word: Word(name: combination, rank: 0.5))
//                }
//            }
//        }
//
//        // Populate with numbers 1 to 9999 (1 to 4-digit numbers)
//        for number in 1...9999 {
//            insertWord(word: Word(name: "\(number)", rank: 0.5))
//        }
//    }
//    
//    private func setupDatabase() {
//        do {
//            let path = NSSearchPathForDirectoriesInDomains(
//                .documentDirectory, .userDomainMask, true
//            ).first!
//            
//            db = try Connection("\(path)/db.sqlite3")
//        } catch {
//            print("Unable to set up database: \(error)")
//        }
//    }
//    
//    private func createWordsTable() {
//        let createTable = wordsTable.create { table in
//            table.column(id, primaryKey: .autoincrement)
//            table.column(word, unique: true) // Assuming each word is unique
//            table.column(rank)
//            table.column(reviewed, defaultValue: false)
//        }
//        
//        do {
//            try db?.run(createTable)
//            print("Created table")
//        } catch {
//            print("Failed to create table: \(error)")
//        }
//    }
//    
////    func insertWord(newWord: String, newRank: Double) {
////        let insert = wordsTable.insert(or: .ignore, word <- newWord, rank <- newRank, reviewed <- false)
////        do {
////            try db?.run(insert)
////            print("Inserted word")
////        } catch {
////            print("Insert failed: \(error)")
////        }
////    }
//    
//    func insertWord(word: Word) {
//        let insert = wordsTable.insert(or: .ignore,
//                                       self.word <- word.name,
//                                       rank <- word.rank,
//                                       reviewed <- word.isNotable)
//        do {
//            try db?.run(insert)
//            print("Inserted word: \(word.name)")
//        } catch {
//            print("Insert failed for \(word.name): \(error)")
//        }
//    }
//    
//    
//    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
//        do {
//            let query = wordsTable.filter(reviewed == false).limit(batchSize)
//            guard let db = db else { return [] }
//            let rows = try db.prepare(query)
//            var result: [Word] = []
//            for row in rows {
//                let wordItem = Word(
//                    name: row[word], // 'word' is the column name for the word itself
//                    rank: row[rank],
//                    isNotable: row[reviewed]
//                )
//                result.append(wordItem)
//            }
//            return result
//        } catch {
//            print("Fetch failed: \(error)")
//            return []
//        }
//    }
//
//    func updateWord(id: Int64, newRank: Double) {
//        let word = wordsTable.filter(self.id == id)
//        do {
//            if try db?.run(word.update(rank <- newRank, reviewed <- true)) ?? 0 > 0 {
//                print("Updated word")
//            } else {
//                print("Word not found")
//            }
//        } catch {
//            print("Update failed: \(error)")
//        }
//    }
//    
//    // Add more functions here for inserting, fetching, updating, and deleting records.
//}

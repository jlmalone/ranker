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
    let reviewed = Expression<Bool>("reviewed")
    
    init() {
        setupDatabase()
        createWordsTable()
    }
    
    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            
            db = try Connection("\(path)/db.sqlite3")
        } catch {
            print("Unable to set up database: \(error)")
        }
    }
    
    private func createWordsTable() {
        let createTable = wordsTable.create { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(word, unique: true) // Assuming each word is unique
            table.column(rank)
            table.column(reviewed, defaultValue: false)
        }
        
        do {
            try db?.run(createTable)
            print("Created table")
        } catch {
            print("Failed to create table: \(error)")
        }
    }
    
    func insertWord(newWord: String, newRank: Double) {
        let insert = wordsTable.insert(or: .ignore, word <- newWord, rank <- newRank, reviewed <- false)
        do {
            try db?.run(insert)
            print("Inserted word")
        } catch {
            print("Insert failed: \(error)")
        }
    }
    
    
    func fetchUnreviewedWords(batchSize: Int) -> [Word] {
        do {
            let query = wordsTable.filter(reviewed == false).limit(batchSize)
            guard let db = db else { return [] }
            let rows = try db.prepare(query)
            var result: [Word] = []
            for row in rows {
                let wordItem = Word(
                    name: row[word], // 'word' is the column name for the word itself
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

    func updateWord(id: Int64, newRank: Double) {
        let word = wordsTable.filter(self.id == id)
        do {
            if try db?.run(word.update(rank <- newRank, reviewed <- true)) ?? 0 > 0 {
                print("Updated word")
            } else {
                print("Word not found")
            }
        } catch {
            print("Update failed: \(error)")
        }
    }
    
    // Add more functions here for inserting, fetching, updating, and deleting records.
}

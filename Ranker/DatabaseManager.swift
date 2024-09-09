import Foundation
import SQLite

class DatabaseManager {
    private var db: Connection?

    let wordsTable = Table("fullwords")
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

//    // Centralized function for the database path
//     func databasePath() -> String {
//        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        let documentsDirectory = paths[0]
//        return documentsDirectory.appendingPathComponent("db.sqlite3").path
//    }


    // Centralized function for the database path
     func databasePath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        // Remove the extra "db.sqlite3" from the path here
        return documentsDirectory.appendingPathComponent("db_full_words.sqlite3").path
    }

    private func setupDatabase() {
        do {
            let path = databasePath()  // Use the centralized function
            db = try Connection(path)
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

        printTableSchema(tableName : "fullwords")
    }

    private func populateInitialDataIfNeeded() {
        let alreadyPopulated = UserDefaults.standard.bool(forKey: "isDatabasePopulated")
        if !alreadyPopulated {
            populateInitialData()
            UserDefaults.standard.set(true, forKey: "isDatabasePopulated")
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

    private func populateInitialData() {
        do {
            try db?.transaction {
                // List of 100 dummy words to prepopulate the database
                let dummyWords = [
                    "alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa",
                    "lambda", "mu", "nu", "xi", "omicron", "pi", "rho", "sigma", "tau", "upsilon",
                    "phi", "chi", "psi", "omega", "apple", "banana", "cherry", "date", "elderberry", "fig",
                    "grape", "honeydew", "kiwi", "lemon", "mango", "nectarine", "orange", "papaya", "quince", "raspberry",
                    "strawberry", "tangerine", "ugli", "vanilla", "watermelon", "xigua", "yam", "zucchini", "almond", "basil",
                    "cinnamon", "dill", "elderflower", "fennel", "ginger", "horseradish", "ivy", "jasmine", "kumquat", "lime",
                    "mint", "nutmeg", "oregano", "parsley", "quinoa", "rosemary", "sage", "thyme", "uva", "valerian",
                    "walnut", "xanthan", "yarrow", "zatar", "azalea", "begonia", "cactus", "daffodil", "echinacea", "fern",
                    "gardenia", "hibiscus", "iris", "jasmine", "kaffir", "lavender", "magnolia", "narcissus", "oak", "poppy"
                ]

                // Insert dummy words into the database
                for word in dummyWords {
                    try insertWordIfNotExists(name: word, rank: 0.5)
                }
            }
            print("Dummy data populated successfully.")
        } catch {
            print("Failed to populate dummy data: \(error)")
        }
    }
}

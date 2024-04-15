
import Foundation
import Combine


class WordSorterViewModel: ObservableObject {
//    @Published var words: [Word] = []
    
    @Published var words: [Word] = []
     @Published var dataVersion = 0 // Add this line
    
    
    private var databaseManager = DatabaseManager()

    init() {
        loadNextBatch()
    }
    
    
    func loadNextBatch() {
        print("Load next batch")
        DispatchQueue.main.async {
            print("Dispatch async")
            self.words = self.databaseManager.fetchUnreviewedWords(batchSize: 20)
            print("words are \(self.words)")
            self.dataVersion += 1 // Increment to signal change
            print("dataversion \(self.dataVersion)")
        }
    }
    
    func saveRankings() {
        for word in words {
            databaseManager.updateWord(word: word)
            print("Saving \(word.name): \(word.rank)")

            // Your logging code here
        }
        loadNextBatch()
    }
    
//    func loadNextBatch() {
//        // This function now implicitly depends on the database to fetch unreviewed words.
//        DispatchQueue.main.async {
//            self.words = self.databaseManager.fetchUnreviewedWords(batchSize: 8)
//        }
//    }
//    
//    func saveRankings() {
//        for word in words {
//            // Here, update the database to mark each word as reviewed.
//            databaseManager.updateWord(word: word)
//            print("\(word.name): \(word.rank)")
//        }
//        // After saving, load the next batch of unreviewed words.
//        loadNextBatch()
//    }
}




//
//
//class WordSorterViewModel: ObservableObject {
//    @Published var words: [Word] = []
//    private var databaseManager = DatabaseManager()
//    private var currentIndex = 0
//    private let batchSize = 8
//
//    init() {
//        loadNextBatch()
//    }
//    
//    func loadNextBatch() {
//        // Async call to database to fetch the next batch of words.
//        DispatchQueue.main.async {
//            self.words.removeAll()  // Clear existing words to load new ones.
//            let fetchedWords = self.databaseManager.fetchUnreviewedWords(batchSize: self.batchSize, offset: self.currentIndex)
//            self.words.append(contentsOf: fetchedWords)
//            self.currentIndex += fetchedWords.count
//        }
//    }
//    
//    func saveRankings() {
//        for word in words {
//            databaseManager.updateWord(word: word)
//        }
//        loadNextBatch()
//    }
//}
















//
//import Foundation
//import Combine
//
//class WordSorterViewModel: ObservableObject {
//    @Published var words: [Word] = []
//    private var databaseManager = DatabaseManager()
//    private var currentIndex = 0
//    private let batchSize = 8
//
//    init() {
//        loadNextBatch()
//    }
//    
//    func loadNextBatch() {
//        // Fetch unreviewed words from the database in batches
//        let fetchedWords = databaseManager.fetchUnreviewedWords(batchSize: batchSize)
//        // If no words were fetched (e.g., all words have been reviewed), you might want to reset currentIndex and start over, or handle it according to your app's logic.
//        if fetchedWords.isEmpty && currentIndex != 0 {
//            currentIndex = 0
//            print("All words have been processed. Consider resetting or handling completion.")
//            // Optionally, you could load the first batch again or handle this scenario as needed.
//            return
//        }
//        
//        words.append(contentsOf: fetchedWords)
//        currentIndex += fetchedWords.count
//    }
//    
//    func saveRankings() {
//        for word in words {
//            databaseManager.updateWord(word: word)
//            print("\(word.name): \(word.rank)")
//        }
//        // Clear the current batch of words to make room for the next batch
//        words.removeAll()
//        loadNextBatch() // Load the next batch after saving.
//    }
//}
//
//































//
//
//import Foundation
//
//import Combine
//
//
//class WordSorterViewModel: ObservableObject {
//    @Published var words: [Word] = []
//    private var allWords: [Word] = [] // Holds the entire set of words
//    private var currentIndex = 0
//
//    init() {
//        // Populate `allWords` with an initial set of hardcoded words
//        allWords = [
//            Word(name: "cat", rank: 0.5),
//            Word(name: "dog", rank: 0.5),
//            Word(name: "bird", rank: 0.5),
//            Word(name: "fish", rank: 0.5),
//            Word(name: "elephant", rank: 0.5),
//            Word(name: "tiger", rank: 0.5),
//            Word(name: "lion", rank: 0.5),
//            Word(name: "bear", rank: 0.5),
//            Word(name: "shark", rank: 0.5),
//            Word(name: "whale", rank: 0.5),
//            Word(name: "dolphin", rank: 0.5),
//            Word(name: "octopus", rank: 0.5),
//            Word(name: "giraffe", rank: 0.5),
//            Word(name: "zebra", rank: 0.5),
//            Word(name: "rhino", rank: 0.5),
//            Word(name: "hippo", rank: 0.5),
//            // Add more as needed...
//        ]
//        loadNextBatch()
//    }
//    
//    func loadNextBatch() {
//        guard currentIndex < allWords.count else {
//            print("All words have been processed.")
//            return
//        }
//        
//        let upperBound = min(currentIndex + 8, allWords.count)
//        let nextBatch = allWords[currentIndex..<upperBound]
//        words = Array(nextBatch)
//        currentIndex += 8
//    }
//    
//    func saveRankings() {
//        // Implement saving logic here. For demonstration, this simply prints the rankings.
//        for word in words {
//            print("\(word.name): \(word.rank)")
//        }
//        // Assume the save to persistence is here.
//        
//        loadNextBatch() // Load the next batch after saving.
//    }
//}
//


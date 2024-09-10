
import Foundation
import Combine


class WordSorterViewModel: ObservableObject {

    // TODO i dont really understand the published annotation. I get the impression that references to it can change
    // the value of it
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


}




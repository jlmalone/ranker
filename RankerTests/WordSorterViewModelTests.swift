import Foundation

import XCTest
@testable import Ranker

class WordSorterViewModelTests: XCTestCase {
    var viewModel: WordSorterViewModel!

    override func setUp() {
        super.setUp()
        if ProcessInfo.processInfo.environment["SIMULATOR_ONLY"] != nil {
            // Proceed with test setup
        } else {
            fatalError("Tests should only be run on the simulator.")
        }
        viewModel = WordSorterViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testLoadNextBatch() {
        viewModel.loadNextBatch()
        XCTAssertFalse(viewModel.words.isEmpty, "Words should be loaded.")
    }

    func testSaveRankings() {
        // Modify words
        viewModel.loadNextBatch()
        viewModel.words = viewModel.words.map { word in
            var mutableWord = word
            mutableWord.rank = 0.8
            mutableWord.isNotable = true
            return mutableWord
        }
        viewModel.saveRankings()

        // Verify that words have been marked as reviewed
        let reviewedWords = viewModel.words.filter { $0.reviewed }
        XCTAssertEqual(reviewedWords.count, viewModel.words.count)
    }
}

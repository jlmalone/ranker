//
//  ProgressViewModel.swift
//  Ranker
//
//  Created by Joseph Malone on 4/11/24.
//

import Foundation

class ProgressViewModel: ObservableObject {
    private var databaseManager = DatabaseManager()
    @Published var reviewedCount: Int = 0
    @Published var unreviewedCount: Int = 0

    func fetchProgress() {
        reviewedCount = databaseManager.countReviewedWords()
        unreviewedCount = databaseManager.countUnreviewedWords()
    }
}

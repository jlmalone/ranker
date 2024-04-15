//
//  ProgressView.swift
//  Ranker
//
//  Created by Joseph Malone on 4/11/24.
//

import Foundation
import SwiftUI
struct ProgressView: View {
    @StateObject var viewModel = ProgressViewModel()

    var body: some View {
        VStack {
            Text("Progress")
                .font(.largeTitle)
                .padding()

            Text("Reviewed Words: \(viewModel.reviewedCount)")
            Text("Unreviewed Words: \(viewModel.unreviewedCount)")

            Button("Refresh Progress") {
                viewModel.fetchProgress()
            }
            .padding()
        }
        .onAppear {
            viewModel.fetchProgress()
        }
    }
}

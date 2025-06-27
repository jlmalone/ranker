
//
//  SettingsView.swift
//  Ranker
//
//  Created by Agent Malone on 9/4/24.
//

import Foundation


import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()

    var body: some View {
        VStack {
            Text("Manage Files")
                .font(.headline)

            Text("Total Data Size: \(viewModel.totalDataSize, specifier: "%.2f") MB")

            Button("Export to Google Drive") {
                viewModel.exportToGoogleDrive()
            }

            Button("Delete All Files") {
                viewModel.deleteAllFiles()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}

class SettingsViewModel: ObservableObject {
    @Published var totalDataSize: Double = 0.0

    func exportToGoogleDrive() {
        // Implement export logic
    }

    func deleteAllFiles() {
        // Implement deletion logic
    }
}

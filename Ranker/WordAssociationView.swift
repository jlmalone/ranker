//
//  WordAssociationView.swift
//  Ranker
//
//  Created by Agent Malone on 9/4/24.
//

import Foundation
import SwiftUI

struct WordAssociationView: View {
    @StateObject var viewModel = WordAssociationViewModel()
    @State private var recordingID = UUID().uuidString
    @State private var transcription = ""
    
    var word: Word

    var body: some View {
        VStack {
            Text("Word Association for \(word.name)")
                .font(.headline)
            
            CustomSlider(value: $viewModel.association.rank)
                .frame(height: 20)
            
            HStack {
                TextField("Transcription", text: $transcription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Save Transcription") {
                    viewModel.saveTranscription(word: word.name, transcription: transcription)
                }
            }
            
            Button("Record Voice") {
                viewModel.startRecording(for: word.name)
            }
            
            Button("Save Recording") {
                viewModel.saveRecording(recordingID: recordingID, word: word.name)
            }
            
            Spacer()
        }
        .padding()
    }
}

class WordAssociationViewModel: ObservableObject {
    @Published var association = Word(name: "", rank: 0.5)
    
    private let databaseManager = DatabaseManager()

    func startRecording(for word: String) {
        // Implement voice recording logic
    }

    func saveRecording(recordingID: String, word: String) {
        // Save the recording metadata in the database
        databaseManager.saveRecordingMetadata(recordingId: recordingID, word: word, transcription: "")
    }
    
    //TODO this was generated and looks worthless
    func saveRecording(for word: String) {
        // Logic to save recording
        let uniqueID = UUID().uuidString
        let filename = "\(word)_\(uniqueID).m4a"
        print("Saving recording to filename: \(filename)")
        // Add the rest of your logic here TODO
    }

    func saveTranscription(word: String, transcription: String) {
        databaseManager.saveRecordingMetadata(recordingId: UUID().uuidString, word: word, transcription: transcription)
    }
}

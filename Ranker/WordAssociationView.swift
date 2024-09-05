import SwiftUI
import Foundation

struct WordAssociationView: View {
    @State private var associationText: String = ""
    @State private var isStarred: Bool = false
    @State private var audioFile: String = ""  // Add an audioFile property
    @State private var isRecording: Bool = false  // Add a state for recording status
    

    
    
    var mainWordId: Int64  // Pass the main word's ID to associate words
    let databaseManager = DatabaseManager()  // Instantiate the DatabaseManager
    
    var body: some View {
        VStack {
            TextField("Enter associated word", text: $associationText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Toggle(isOn: $isStarred) {
                Text("Star this association")
            }
            .padding()
            Button("Add Association") {
                // Correcting the argument names to match the function signature
                databaseManager.addWordAssociation(word: "example", associationText: associationText.lowercased(), isStarred: isStarred)
            }

            .padding()
            
            // Button to start recording
            Button(isRecording ? "Stop Recording" : "Start Recording") {
                if isRecording {
                    stopRecording()  // Call stopRecording function when user stops recording
                } else {
                    startRecording()  // Call startRecording when user starts
                }
            }
            .padding()
            
            // Placeholder for playing audio
            if !audioFile.isEmpty {
                Button("Play Recording") {
                    playAudio(audioFile)  // Add function to play the recorded audio
                }
                .padding()
            }
        }
        .navigationTitle("Word Association")
    }

    // Start recording functionality
    func startRecording() {
        // Your implementation here
        isRecording = true
        print("Recording started")
    }
    
    // Stop recording functionality
    func stopRecording() {
        isRecording = false
        let uniqueID = UUID().uuidString
        audioFile = "recording_\(uniqueID).m4a"

        // Save metadata to the database
        databaseManager.saveRecordingMetadata(recordingId: uniqueID, word: "associated_word_here", transcription: "transcription_text_here", audioFileName: audioFile, isStarred: isStarred)
        
        print("Recording stopped, saved as \(audioFile)")
    }
    // Play the recorded audio
    func playAudio(_ file: String) {
        // Your implementation for playing the audio
        print("Playing audio: \(file)")
    }
}

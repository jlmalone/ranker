import Foundation
import SwiftUI

struct AssociatedIdeasView: View {
    let word: String  // The word passed from the previous screen

    @State private var associatedWord: String = ""  // State to hold the input


    var body: some View {
        VStack {
            // Title at the top displaying the word
            Text("\(word)")
                .font(.largeTitle)
                .padding()

            Spacer()  // Pushes content to the top and bottom


            TextField("Enter associated word", text: $associatedWord)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Spacer()  // Pushes content to the top and bottom


            Text("\(word)")
                .padding()

            RecorderWidgetView()

            //TODO I want a recorder widget here. It should have a record button, when i hit the record button i should see some
            //animated feedback that the widget is recording along with a time indicator for the length of time recorded so far. A stop button should be visible when and only when it is recording.
            //after i hit the stop button I should see a spinner or pending indicator while a transcript is being processed from the recording.
            //that transcript should be generated.
            //That transcript when ready should become visible in a scrollable textview with only 6 lines of small space separated text all lowercase.
            //A reset button should now be visible because a recording has occurred. If i click reset i get
            //a confirmation dialog that throws away the recording and the transcript.

            Spacer()

            // "Done" button at the bottom
            Button(action: {
                // TODO: Save the data to the database
                // For now It just shows a confirmation dialog listing:
                //the filename for the recording if it exists
                //the filename for the transcript in it exists
                //the truncated version of the Textfield text that the user input

                print("Save associated ideas for \(word)")  // Debug print
            }) {
                Text("Done")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)  // Space from the bottom of the screen
        }
        .navigationBarTitleDisplayMode(.inline)  // Shows title inline in the navigation bar
    }
}


//
//
//import SwiftUI
//import Foundation
//
//struct WordAssociationView: View {
//    @State private var associationText: String = ""
//    @State private var isStarred: Bool = false
//    @State private var audioFile: String = ""  // Add an audioFile property
//    @State private var isRecording: Bool = false  // Add a state for recording status
//
//
//
//
//    var mainWordId: Int64  // Pass the main word's ID to associate words
//    let databaseManager = DatabaseManager()  // Instantiate the DatabaseManager
//
//    var body: some View {
//        VStack {
//            TextField("Enter associated word", text: $associationText)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            Toggle(isOn: $isStarred) {
//                Text("Star this association")
//            }
//            .padding()
//            Button("Add Association") {
//                // Correcting the argument names to match the function signature
//                databaseManager.addWordAssociation(word: "example", associationText: associationText.lowercased(), isStarred: isStarred)
//            }
//
//            .padding()
//
//            // Button to start recording
//            Button(isRecording ? "Stop Recording" : "Start Recording") {
//                if isRecording {
//                    stopRecording()  // Call stopRecording function when user stops recording
//                } else {
//                    startRecording()  // Call startRecording when user starts
//                }
//            }
//            .padding()
//
//            // Placeholder for playing audio
//            if !audioFile.isEmpty {
//                Button("Play Recording") {
//                    playAudio(audioFile)  // Add function to play the recorded audio
//                }
//                .padding()
//            }
//        }
//        .navigationTitle("Word Association")
//    }
//
//    // Start recording functionality
//    func startRecording() {
//        // Your implementation here
//        isRecording = true
//        print("Recording started")
//    }
//
//    // Stop recording functionality
//    func stopRecording() {
//        isRecording = false
//        let uniqueID = UUID().uuidString
//        audioFile = "recording_\(uniqueID).m4a"
//
//        // Save metadata to the database
//        databaseManager.saveRecordingMetadata(recordingId: uniqueID, word: "associated_word_here", transcription: "transcription_text_here", audioFileName: audioFile, isStarred: isStarred)
//
//        print("Recording stopped, saved as \(audioFile)")
//    }
//    // Play the recorded audio
//    func playAudio(_ file: String) {
//        // Your implementation for playing the audio
//        print("Playing audio: \(file)")
//    }
//}

import Foundation

import SwiftUI

struct RecorderWidgetView: View {

    @State private var isRecording: Bool = false  // State to track recording
    @State private var recordingDuration: Double = 0  // State to track the recording duration
    @State private var transcript: String? = nil  // State to hold the transcript
    @State private var isProcessing: Bool = false  // State to track processing state
    @State private var showReset: Bool = false  // State to show the reset button

    @State private var recordingTimer: Timer?  // Timer logic for recording

    var body: some View {
        VStack {
            if !isRecording {
                Button(action: {
                    startRecording()
                }) {
                    Text("Record")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                // Animated feedback while recording (simple pulsing view)
                Text("Recording... \(Int(recordingDuration))s")
                    .font(.title2)
                    .foregroundColor(.red)

                Button(action: {
                    stopRecording()
                }) {
                    Text("Stop")
                        .font(.title)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            // Show spinner while processing transcript
            if isProcessing {
//                ProgressView("Processing Transcript...")
            }

            // Transcript scrollable text view
            if let transcript = transcript {
                ScrollView {
                    Text(transcript)
                        .font(.body)
                        .padding()
                        .lineLimit(6)  // Limit to 6 lines
                        .truncationMode(.tail)
                        .frame(height: 100)  // Fixed height for scroll
                }
            }

            // Reset button
            if showReset {
                Button(action: {
                    resetRecording()
                }) {
                    Text("Reset")
                        .font(.title)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }

    // Define the startRecording method
    private func startRecording() {
        isRecording = true
        showReset = false
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            recordingDuration += 1
        }
    }

    // Define the stopRecording method
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        isProcessing = true

        // Simulate transcript processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            transcript = "This is a sample transcript of the recorded audio."
            isProcessing = false
            showReset = true
        }
    }

    // Define the resetRecording method
    private func resetRecording() {
        recordingDuration = 0
        transcript = nil
        showReset = false
    }
}

struct RecorderWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderWidgetView()
    }
}

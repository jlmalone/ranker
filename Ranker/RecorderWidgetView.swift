import Foundation

import SwiftUI

//TODO this is good but it needs to actually start recording audio
//
//make it so
//after the recording, a transcript needs to be generated.
//both should be saved.
//it should be saved on the device using a separate FileManager (TODO)
//file format:
//  {localsavedirectory todo need help}/{seedword}_recording_{date in yyyy-MM-dd-HH-mm-ss.mp3}
//  {localsavedirectory todo need help}/{seedword}_transcript_{date in yyyy-MM-dd-HH-mm-ss.txt}
// transcript should be all lowercase, period separated between phrases. space separated between words.

// If i hit the Reset button, I should see a confirmation dialog with the ability to cancel. CANCEL  DELETE are the two options
//



//I articulated myself differently previously for a similar intention


            //TODO I want a recorder widget here. It should have a record button, when i hit the record button i should see some
            //animated feedback that the widget is recording along with a time indicator for the length of time recorded so far. A stop button should be visible when and only when it is recording.
            //after i hit the stop button I should see a spinner or pending indicator while a transcript is being processed from the recording.
            //that transcript should be generated.
            //That transcript when ready should become visible in a scrollable textview with only 6 lines of small space separated text all lowercase.
            //A reset button should now be visible because a recording has occurred. If i click reset i get
            //a confirmation dialog that throws away the recording and the transcript.



import AVFoundation

struct RecorderWidgetView: View {

    public var seedWord: String

    @State private var isRecording: Bool = false  // State to track recording
    @State private var recordingDuration: Double = 0  // State to track the recording duration
    @State private var transcript: String? = nil  // State to hold the transcript
    @State private var isProcessing: Bool = false  // State to track processing state
    @State private var showReset: Bool = false  // State to show the reset button

    @State private var recordingTimer: Timer?  // Timer logic for recording
    @State private var audioRecorder: AVAudioRecorder?  // The audio recorder
    @State private var audioPlayer: AVAudioPlayer?  // For playback of recorded audio

    @State private var audioFilename: URL?  // File URL where the audio is stored

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
                //TODO fix
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

            // Play recorded audio button
            if audioFilename != nil && !isRecording {
                Button(action: {
                    playRecording()
                }) {
                    Text("Play Recorded Audio")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .onAppear {
            requestPermission()
        }
    }

    // Request microphone access
    private func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone access denied")
            }
        }
    }

    // Define the startRecording method
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            // Prepare file URL for storing audio
            let fileName = UUID().uuidString + ".m4a"
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = paths[0].appendingPathComponent(fileName)
            audioFilename = fileURL

            // Setup audio recorder settings
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            isRecording = true
            showReset = false
            recordingDuration = 0

            // Start recording timer
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                recordingDuration += 1
            }

        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    // Define the stopRecording method
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        audioRecorder?.stop()
        audioRecorder = nil

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
        audioFilename = nil
    }

    // Define method to play the recorded audio
    private func playRecording() {
        guard let audioFilename = audioFilename else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.play()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }
}

struct RecorderWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderWidgetView(seedWord: "todo")
    }
}

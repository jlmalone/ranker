import SwiftUI
import AVFoundation
import Speech

struct RecorderWidgetView: View {
    public var seedWord: String

    @State private var isRecording = false
    @State private var recordingDuration: Double = 0
    @State private var transcript: String? = nil
    @State private var isProcessing = false
    @State private var showReset = false
    @State private var showAddWords = false

    @State private var recordingTimer: Timer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioFilename: URL?

    @State private var parsedKeywords: [String] = []

    private let databaseManager = DatabaseManager()

    var body: some View {
        VStack {
            if !isRecording {
                Button(action: { startRecording() }) {
                    Text("Record")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("Recording... \(Int(recordingDuration))s")
                    .font(.title2)
                    .foregroundColor(.red)

                Button(action: { stopRecording() }) {
                    Text("Stop")
                        .font(.title)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if isProcessing {
                SwiftUI.ProgressView("Transcribing...")
                    .padding()
            }

            if let transcript = transcript {
                ScrollView {
                    Text(transcript)
                        .font(.body)
                        .padding()
                        .lineLimit(6)
                        .truncationMode(.tail)
                        .frame(height: 100)
                }

                if !parsedKeywords.isEmpty {
                    Button("Add \(parsedKeywords.count) words to seed corpus") {
                        for keyword in parsedKeywords {
                            databaseManager.insertWordFromDump(keyword, wordSource: "voice_transcript")
                        }
                        showAddWords = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(showAddWords)

                    if showAddWords {
                        Text("Added!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            if showReset {
                Button(action: { resetRecording() }) {
                    Text("Reset")
                        .font(.title)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if audioFilename != nil && !isRecording {
                Button(action: { playRecording() }) {
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
        .onAppear { requestPermissions() }
    }

    private func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    private func currentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return dateFormatter.string(from: Date())
    }

    private func resetRecording() {
        let alert = UIAlertController(title: "Reset Recording", message: "Delete the recording and transcript?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            if let audioFilename = audioFilename {
                try? FileManager.default.removeItem(at: audioFilename)
            }
            recordingDuration = 0
            transcript = nil
            showReset = false
            showAddWords = false
            audioFilename = nil
            parsedKeywords = []
        })
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }

    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            let dateString = currentDateString()
            let audioFileName = "\(seedWord)_recording_\(dateString).m4a"
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = paths[0].appendingPathComponent(audioFileName)
            audioFilename = fileURL

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            isRecording = true
            showReset = false
            showAddWords = false
            recordingDuration = 0

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                recordingDuration += 1
            }
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil

        guard let audioURL = audioFilename else {
            showReset = true
            return
        }

        isProcessing = true
        transcribeAudio(url: audioURL)
    }

    private func transcribeAudio(url: URL) {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            DispatchQueue.main.async {
                transcript = "[Speech recognition unavailable]"
                isProcessing = false
                showReset = true
            }
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                if let result = result, result.isFinal {
                    let text = result.bestTranscription.formattedString.lowercased()
                    transcript = text
                    parsedKeywords = parseKeywords(from: text)
                    isProcessing = false
                    showReset = true
                } else if let error = error {
                    transcript = "[Transcription error: \(error.localizedDescription)]"
                    isProcessing = false
                    showReset = true
                }
            }
        }
    }

    private func parseKeywords(from text: String) -> [String] {
        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;.!?"))
        let tokens = text.components(separatedBy: separators)
        var unique = Set<String>()
        for token in tokens {
            let cleaned = token.trimmingCharacters(in: .punctuationCharacters).lowercased()
            if cleaned.count >= 2 { unique.insert(cleaned) }
        }
        return Array(unique).sorted()
    }

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

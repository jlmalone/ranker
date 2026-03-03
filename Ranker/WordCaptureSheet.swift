// WordCaptureSheet: Bottom sheet for capturing thoughts about a word.
// Text note, voice recording, star toggle, previous notes.

import SwiftUI
import AVFoundation
import Speech

struct WordCaptureSheet: View {
    let word: Word
    let databaseManager: DatabaseManager
    var onDismiss: (() -> Void)?

    @State private var noteText = ""
    @State private var isRecording = false
    @State private var recordingDuration: Double = 0
    @State private var transcript: String? = nil
    @State private var isProcessing = false
    @State private var savedMessage: String? = nil

    @State private var recordingTimer: Timer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioFilename: URL?

    @State private var previousNotes: [(text: String, date: String)] = []
    @State private var previousRecordings: [(filename: String, transcript: String?, date: String)] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Word display
                    Text(word.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    // Rank indicator
                    HStack {
                        Text("Rank:")
                            .foregroundColor(.secondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                Rectangle()
                                    .fill(rankColor)
                                    .frame(width: geo.size.width * word.rank, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Quick text note
                    HStack {
                        TextField("What does this remind you of?", text: $noteText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { saveNote() }

                        Button(action: saveNote) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(noteText.isEmpty ? .gray : .blue)
                        }
                        .disabled(noteText.isEmpty)
                    }
                    .padding(.horizontal)

                    // Voice record button
                    HStack {
                        if !isRecording {
                            Button(action: startRecording) {
                                HStack {
                                    Image(systemName: "mic.fill")
                                    Text("Record")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        } else {
                            HStack {
                                Text("Recording... \(Int(recordingDuration))s")
                                    .foregroundColor(.red)
                                Button(action: stopRecording) {
                                    HStack {
                                        Image(systemName: "stop.fill")
                                        Text("Stop")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                        }

                        Spacer()

                        // Star toggle
                        Image(systemName: word.isNotable ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal)

                    if isProcessing {
                        SwiftUI.ProgressView("Transcribing...")
                            .padding()
                    }

                    if let transcript = transcript {
                        Text(transcript)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    // Saved confirmation
                    if let msg = savedMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    savedMessage = nil
                                }
                            }
                    }

                    // Previous notes
                    if !previousNotes.isEmpty {
                        Divider()
                        Text("Previous Notes")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(previousNotes.indices, id: \.self) { i in
                            HStack {
                                Text(previousNotes[i].text)
                                    .font(.body)
                                Spacer()
                                Text(previousNotes[i].date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }

                    if !previousRecordings.isEmpty {
                        Divider()
                        Text("Recordings")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(previousRecordings.indices, id: \.self) { i in
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(.blue)
                                Text(previousRecordings[i].transcript ?? previousRecordings[i].filename)
                                    .font(.caption)
                                    .lineLimit(2)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss?() }
                }
            }
            .onAppear {
                loadPreviousData()
                requestPermissions()
            }
        }
    }

    private var rankColor: Color {
        if word.rank < 0.3 { return .red }
        if word.rank > 0.7 { return .green }
        return .gray
    }

    private func saveNote() {
        guard !noteText.isEmpty else { return }
        do {
            try databaseManager.addWordAssociation(mainWordId: word.id, text: noteText, isStarred: false)
            savedMessage = "Saved: \"\(noteText)\""
            previousNotes.insert((text: noteText, date: "Just now"), at: 0)
            noteText = ""
        } catch {
            savedMessage = "Error saving note"
        }
    }

    private func loadPreviousData() {
        // Load existing associations and recordings for this word
        // Using the associations_db tables
        previousNotes = databaseManager.fetchAssociations(forWordId: word.id)
        previousRecordings = databaseManager.fetchRecordings(forWordId: word.id)
    }

    // MARK: - Voice Recording (reused from RecorderWidgetView)

    private func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "\(word.name)_recording_\(dateString).m4a"
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = paths[0].appendingPathComponent(fileName)
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
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                recordingDuration += 1
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil

        guard let audioURL = audioFilename else { return }

        isProcessing = true

        // Save recording to DB
        do {
            try databaseManager.saveAudioRecording(
                mainWordId: word.id,
                audioFilename: audioURL.lastPathComponent,
                transcript: nil,
                isStarred: false
            )
        } catch {
            print("Failed to save recording: \(error)")
        }

        // Transcribe
        transcribeAudio(url: audioURL)
    }

    private func transcribeAudio(url: URL) {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            DispatchQueue.main.async {
                transcript = "[Speech recognition unavailable]"
                isProcessing = false
            }
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                if let result = result, result.isFinal {
                    transcript = result.bestTranscription.formattedString.lowercased()
                    isProcessing = false
                    savedMessage = "Recording saved"
                } else if error != nil {
                    transcript = nil
                    isProcessing = false
                    savedMessage = "Recording saved (no transcript)"
                }
            }
        }
    }
}

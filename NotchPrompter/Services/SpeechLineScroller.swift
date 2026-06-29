import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechLineScroller: ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var isSpeaking = false
    @Published private(set) var level: Float = 0
    @Published private(set) var highlightedWordIndices: Set<Int> = []

    var onLineAdvance: ((Int) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    private var lines: [PrompterLine] = []
    private var scriptWords: [String] = []
    private var scrollOffset: CGFloat = 0
    private var viewportHeight: CGFloat = 0
    private var matchedWordCount = 0
    private var lastCompletedLineIndex = -1
    private var silenceDeadline: Date?
    private var configuredScriptText = ""

    func updateLayout(text: String, lines: [PrompterLine], scrollOffset: CGFloat, viewportHeight: CGFloat) {
        self.lines = lines
        self.scrollOffset = scrollOffset
        self.viewportHeight = viewportHeight

        if text != configuredScriptText {
            configuredScriptText = text
            scriptWords = PrompterTextTokenizer.normalizedWords(from: text)
            matchedWordCount = 0
            highlightedWordIndices = []
            lastCompletedLineIndex = -1
        }
    }

    func resetProgress() {
        matchedWordCount = 0
        highlightedWordIndices = []
        lastCompletedLineIndex = -1
    }

    func start(sensitivity: Double) async throws {
        guard !isListening else { return }

        let micGranted = await requestMicrophoneAccess()
        guard micGranted else { throw VoiceActivityError.microphoneDenied }

        let speechGranted = await requestSpeechAccess()
        guard speechGranted else { throw VoiceActivityError.speechDenied }

        speechRecognizer = SFSpeechRecognizer(locale: .current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceActivityError.speechUnavailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { throw VoiceActivityError.speechUnavailable }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = false
        recognitionRequest.taskHint = .dictation

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let threshold = -55 + Float((1 - sensitivity) * 30)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }

            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))
            let db = 20 * log10(max(rms, 0.000_01))
            let speakingNow = db > threshold

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.level = min(1, max(0, (db + 60) / 40))
                if speakingNow {
                    self.silenceDeadline = Date().addingTimeInterval(0.25)
                    self.isSpeaking = true
                } else if let deadline = self.silenceDeadline {
                    self.isSpeaking = Date() < deadline
                } else {
                    self.isSpeaking = false
                }
            }
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.processTranscript(result.bestTranscription.formattedString)
                }
                if error != nil {
                    // Recognition tasks end after pauses; presentation restart handles full reset.
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    func stop() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        isListening = false
        isSpeaking = false
        level = 0
        silenceDeadline = nil
    }

    private func processTranscript(_ transcript: String) {
        guard !scriptWords.isEmpty else { return }

        syncMatchedWords(from: transcript)
        checkLineAdvance()
    }

    private func syncMatchedWords(from transcript: String) {
        let spokenWords = transcript
            .split(whereSeparator: \.isWhitespace)
            .map { PrompterTextTokenizer.normalizeWord(String($0)) }
            .filter { !$0.isEmpty }

        guard !spokenWords.isEmpty else { return }

        var bestMatch = matchedWordCount

        for start in 0..<spokenWords.count {
            var scriptIndex = matchedWordCount
            var spokenIndex = start
            var localBest = matchedWordCount

            while spokenIndex < spokenWords.count, scriptIndex < scriptWords.count {
                if wordsMatch(spoken: spokenWords[spokenIndex], script: scriptWords[scriptIndex]) {
                    localBest = scriptIndex + 1
                    scriptIndex += 1
                    spokenIndex += 1
                } else {
                    break
                }
            }

            bestMatch = max(bestMatch, localBest)
        }

        guard bestMatch > matchedWordCount else { return }

        matchedWordCount = bestMatch
        highlightedWordIndices = Set(0..<matchedWordCount)
    }

    private func checkLineAdvance() {
        guard !lines.isEmpty else { return }

        let activeIndex = PrompterLineLayout.activeLineIndex(
            at: scrollOffset,
            viewportHeight: viewportHeight,
            lines: lines
        )
        guard activeIndex < lines.count else { return }
        guard activeIndex > lastCompletedLineIndex else { return }

        let line = lines[activeIndex]
        guard !line.words.isEmpty else { return }

        let requiredMatches = line.lastWordIndex + 1
        guard matchedWordCount >= requiredMatches else { return }

        lastCompletedLineIndex = activeIndex
        onLineAdvance?(activeIndex)
    }

    private func wordsMatch(spoken: String, script: String) -> Bool {
        guard !spoken.isEmpty, !script.isEmpty else { return false }
        if spoken == script { return true }
        if spoken.count >= 3, script.hasPrefix(spoken) { return true }
        if script.count >= 3, spoken.hasPrefix(script) { return true }
        return false
    }

    private func requestMicrophoneAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    private func requestSpeechAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

enum VoiceActivityError: LocalizedError {
    case microphoneDenied
    case speechDenied
    case speechUnavailable

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "Microphone access is required. Enable it in System Settings → Privacy & Security → Microphone."
        case .speechDenied:
            return "Speech recognition is required for line-by-line scrolling. Enable it in System Settings → Privacy & Security → Speech Recognition."
        case .speechUnavailable:
            return "Speech recognition is not available on this Mac."
        }
    }
}

import ComposableArchitecture
import Speech
import AVFoundation

@DependencyClient
struct SpeechClient {
    var requestAuthorization: () async -> SFSpeechRecognizerAuthorizationStatus = { .notDetermined }
    var startTask: (_ request: SFSpeechAudioBufferRecognitionRequest) -> AsyncThrowingStream<String, Error> = { _ in .finished() }
}

extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}

extension SpeechClient: DependencyKey {
    static let liveValue = SpeechClient(
        requestAuthorization: {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        },
        startTask: { request in
            AsyncThrowingStream { continuation in
                // Check current authorization status
                let currentStatus = SFSpeechRecognizer.authorizationStatus()
                
                // If not authorized, fail immediately with clear message
                guard currentStatus == .authorized else {
                    continuation.finish(throwing: NSError(
                        domain: "SpeechClient",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized. Please enable in Settings."]
                    ))
                    return
                }
                
                let audioSession = AVAudioSession.sharedInstance()
                guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
                    continuation.finish(throwing: NSError(domain: "SpeechClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available for en-US"]))
                    return
                }
                if !speechRecognizer.isAvailable {
                    continuation.finish(throwing: NSError(domain: "SpeechClient", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available"]))
                    return
                }
                let audioEngine = AVAudioEngine()
                
                // Start async work in a Task
                Task {
                    do {
                        // Request microphone permission if needed
                        let micPermission = await AVAudioApplication.requestRecordPermission()
                        guard micPermission else {
                            continuation.finish(throwing: NSError(
                                domain: "SpeechClient",
                                code: 4,
                                userInfo: [NSLocalizedDescriptionKey: "Microphone access denied. Please enable in Settings."]
                            ))
                            return
                        }
                        
                        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                        
                        let inputNode = audioEngine.inputNode
                        let recordingFormat = inputNode.outputFormat(forBus: 0)
                        
                        // Safety: Remove any existing tap before installing a new one
                        inputNode.removeTap(onBus: 0)
                        
                        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                            request.append(buffer)
                        }
                        
                        audioEngine.prepare()
                        try audioEngine.start()
                        
                        let recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                            if let result = result {
                                continuation.yield(result.bestTranscription.formattedString)
                            }
                            if let error = error {
                                continuation.finish(throwing: error)
                                audioEngine.stop()
                                inputNode.removeTap(onBus: 0)
                            }
                            if result?.isFinal == true {
                                continuation.finish()
                                audioEngine.stop()
                                inputNode.removeTap(onBus: 0)
                            }
                        }
                        
                        continuation.onTermination = { @Sendable _ in
                            audioEngine.stop()
                            inputNode.removeTap(onBus: 0)
                            recognitionTask.cancel()
                            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                        }
                        
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    )
}

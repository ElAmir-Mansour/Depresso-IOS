import ComposableArchitecture
import Speech
import AVFoundation

@DependencyClient
struct SpeechClient {
    var requestAuthorization: () async -> SFSpeechRecognizerAuthorizationStatus = { .notDetermined }
    var startTask: @Sendable (_ request: SFSpeechAudioBufferRecognitionRequest) -> AsyncThrowingStream<String, Error> = { _ in .finished() }
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
                let audioSession = AVAudioSession.sharedInstance()
                let audioEngine = AVAudioEngine()
                let speechRecognizer = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
                
                var recognitionTask: SFSpeechRecognitionTask?
                
                continuation.onTermination = { @Sendable _ in
                    if audioEngine.isRunning {
                        audioEngine.stop()
                        audioEngine.inputNode.removeTap(onBus: 0)
                    }
                    recognitionTask?.cancel()
                }
                
                Task {
                    do {
                        // 1. Check Speech Authorization
                        let speechAuth = SFSpeechRecognizer.authorizationStatus()
                        if speechAuth != .authorized {
                            continuation.finish(throwing: SpeechError.notAuthorized)
                            return
                        }
                        
                        // 2. Request Microphone Permission
                        let micPermission: Bool
                        if #available(iOS 17.0, *) {
                            micPermission = await AVAudioApplication.requestRecordPermission()
                        } else {
                            micPermission = await audioSession.requestRecordPermission()
                        }
                        
                        if !micPermission {
                            continuation.finish(throwing: SpeechError.microphoneDenied)
                            return
                        }
                        
                        // 3. Configure Audio Session
                        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
                        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                        
                        // 4. Setup Audio Engine
                        let inputNode = audioEngine.inputNode
                        let recordingFormat = inputNode.outputFormat(forBus: 0)
                        
                        inputNode.removeTap(onBus: 0)
                        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                            request.append(buffer)
                        }
                        
                        audioEngine.prepare()
                        try audioEngine.start()
                        
                        // 5. Start Recognition Task
                        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                            if let result = result {
                                continuation.yield(result.bestTranscription.formattedString)
                            }
                            
                            if let error = error {
                                continuation.finish(throwing: error)
                            } else if result?.isFinal == true {
                                continuation.finish()
                            }
                        }
                        
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    )
}

enum SpeechError: Error, LocalizedError {
    case notAuthorized
    case microphoneDenied
    case recognizerUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Speech recognition not authorized. Please enable in Settings."
        case .microphoneDenied: return "Microphone access denied. Please enable in Settings."
        case .recognizerUnavailable: return "Speech recognizer is currently unavailable."
        }
    }
}

private extension AVAudioSession {
    func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

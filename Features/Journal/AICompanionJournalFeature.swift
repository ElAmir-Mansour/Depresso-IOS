// In Features/Journal/AICompanionJournalFeature.swift
import Foundation
import ComposableArchitecture
import CoreMotion
import FirebaseAI
import SwiftData
import SwiftUI
import Speech // Added import

@Reducer
struct AICompanionJournalFeature {
      private enum CancelID { 
          case motion 
          case speech // Added CancelID
      }

      @ObservableState
      struct State: Equatable {
          static func == (lhs: AICompanionJournalFeature.State, rhs: AICompanionJournalFeature.State) -> Bool {
              return lhs.messages.map(\.id) == rhs.messages.map(\.id) &&
                     lhs.textInput == rhs.textInput &&
                     lhs.isSendingMessage == rhs.isSendingMessage
          }
          var messages: [ChatMessage] = []
          var textInput: String = ""
          var isSendingMessage: Bool = false
          @Presents var alert: AlertState<Action.Alert>?
          var journalSessionStartDate: Date?
          var editCount: Int = 0
          var motionSamples: [CMAcceleration] = [] // Ensure correct type CMAcceleration
          var currentWPM: Double = 0
          var currentSessionDuration: TimeInterval = 0
          var currentMotionData: [CMAcceleration] = [] // Ensure correct type CMAcceleration
          var currentEditCountForSubmission: Int = 0
          
          // Voice Journaling State
          var isRecording: Bool = false
          var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
      }

      enum Action: BindableAction {
          case binding(BindingAction<State>)
          case sendButtonTapped
          case aiResponseReceived(Result<ChatMessage, Error>)
          case alert(PresentationAction<Alert>)
          case task
          case motionUpdate(MotionData)
          case userDidBackspace
          case submissionDataLoaded(Result<DailyMetrics, Error>)
          case messagesLoaded(Result<[ChatMessage], Error>)
          case userMessageSaved(Result<ChatMessage, Error>)
          case aiMessageSaved(Result<ChatMessage, Error>)
          
          // Voice Actions
          case recordButtonTapped
          case speechResult(String)
          case speechError(String)
          case checkSpeechAuthorization

          case retryLastMessage // ADDED

          @CasePathable
          enum Alert: Equatable {
              case retry
          }
      }

      @Dependency(\.aiClient) var aiClient
      @Dependency(\.backendAIClient) var backendAIClient
      @Dependency(\.motionClient) var motionClient
      @Dependency(\.speechClient) var speechClient // Added dependency
      @Dependency(\.healthClient) var healthClient
      @Dependency(\.dataSubmissionClient) var dataSubmissionClient
      @Dependency(\.uuid) var uuid
      @Dependency(\.modelContext) var modelContext

      private func history(from messages: [ChatMessage]) -> [ModelContent] {
           return messages.map { message in
                let role = message.isFromCurrentUser ? "user" : "model"
                return ModelContent(role: role, parts: [message.content])
           }
      }

    @MainActor
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
             case .task:
                // Load messages and start motion updates if empty
                if state.messages.isEmpty {
                    state.journalSessionStartDate = Date()
                    return .merge(
                        .run { [modelContext] send in
                            let descriptor = FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.timestamp)])
                            await send(.messagesLoaded(Result { 
                                try await MainActor.run {
                                    try modelContext.context.fetch(descriptor)
                                }
                            }))
                        },
                        .run { [motionClient] send in
                            for await motionData in motionClient.start() {
                                await send(.motionUpdate(motionData))
                            }
                        }
                        .cancellable(id: CancelID.motion)
                    )
                }
                
                return .none
                
             case .checkSpeechAuthorization:
                return .run { [speechClient] send in
                    _ = await speechClient.requestAuthorization()
                }
             case .messagesLoaded(.success(let messages)):
                 state.messages = messages
                 if messages.isEmpty {
                     let greeting = ChatMessage(content: "Hello! How are you feeling today?", isFromCurrentUser: false)
                     state.messages.append(greeting)
                 }
                 return .none
             case .messagesLoaded(.failure(let error)):
                 state.alert = AlertState { TextState("Error") } message: { TextState("Could not load journal history. \(error.localizedDescription)") }
                 return .none
             case .motionUpdate(let motionData):
                 state.motionSamples.append(motionData.userAcceleration)
                 return .none
             case .userDidBackspace:
                 state.editCount += 1
                 return .none
             case .binding:
                 return .none

            case .sendButtonTapped:
    guard !state.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }

    // Extract data BEFORE async operations (avoid capturing non-Sendable ChatMessage)
    let messageContent = state.textInput
    let prompt = state.textInput

    state.currentMotionData = state.motionSamples
    state.currentEditCountForSubmission = state.editCount
    state.currentSessionDuration = Date().timeIntervalSince(state.journalSessionStartDate ?? Date())
    let wordCount = messageContent.split(whereSeparator: \.isWhitespace).count
    state.currentWPM = state.currentSessionDuration > 0 ? (Double(wordCount) / state.currentSessionDuration) * 60.0 : 0

    state.textInput = ""
    state.isSendingMessage = true
    state.journalSessionStartDate = Date()
    state.editCount = 0
    state.motionSamples = []
    
    return .run { [modelContext, backendAIClient, healthClient] send in
        // Create and save user message on MainActor
        await MainActor.run {
            let userMessage = ChatMessage(content: messageContent, isFromCurrentUser: true)
            modelContext.context.insert(userMessage)
            do {
                try modelContext.context.save()
                send(.userMessageSaved(.success(userMessage)))
            } catch {
                send(.userMessageSaved(.failure(error)))
            }
        }

        // Fetch AI response and health metrics
        do {
            let responseText = try await backendAIClient.generateResponse([], prompt, nil)
            let metricsArray = try await healthClient.fetchHealthMetrics()
            let steps = metricsArray.first(where: { $0.type == .steps })?.value ?? 0.0
            let energy = metricsArray.first(where: { $0.type == .calories })?.value ?? 0.0
            let heartRate = metricsArray.first(where: { $0.type == .heartRate })?.value ?? 0.0
            let dailyMetrics = DailyMetrics(steps: steps, activeEnergy: energy, heartRate: heartRate)

            // Save AI message on MainActor
            await MainActor.run {
                let aiMessage = ChatMessage(content: responseText, isFromCurrentUser: false)
                modelContext.context.insert(aiMessage)
                do {
                    try modelContext.context.save()
                    send(.aiMessageSaved(.success(aiMessage)))
                } catch {
                    send(.aiMessageSaved(.failure(error)))
                }
            }

            await send(.submissionDataLoaded(.success(dailyMetrics)))

        } catch {
            print("❌ Error during concurrent fetch/save: \(error)")
            await send(.aiMessageSaved(.failure(error)))
            await send(.submissionDataLoaded(.failure(error)))
        }
    }

             case .userMessageSaved(.success(let message)):
                 withAnimation {
                     if !state.messages.contains(where: { $0.id == message.id }) {
                         state.messages.append(message)
                     }
                 }
                 return .none
             case .userMessageSaved(.failure(let error)):
                 state.alert = AlertState { TextState("Save Error") } message: { TextState("Could not save your message: \(error.localizedDescription)") }
                 state.isSendingMessage = false
                 return .none
             case .aiMessageSaved(.success(let message)):
                  withAnimation {
                      if !state.messages.contains(where: { $0.id == message.id }) {
                          state.messages.append(message)
                      }
                  }
                  state.isSendingMessage = false
                  return .none
             case .aiMessageSaved(.failure(let error)):
                 state.isSendingMessage = false
                 state.alert = AlertState {
                     TextState("Save Error")
                 } actions: {
                     ButtonState(action: .retry) {
                         TextState("Retry")
                     }
                     ButtonState(role: .cancel) {
                         TextState("Cancel")
                     }
                 } message: {
                     TextState("Could not save the AI response: \(error.localizedDescription)")
                 }
                 return .none
             case .alert(.presented(.retry)):
                 return .send(.retryLastMessage)
             case .retryLastMessage:
                 guard let lastUserMessage = state.messages.last(where: { $0.isFromCurrentUser }) else { return .none }
                 state.isSendingMessage = true
                 let prompt = lastUserMessage.content
                 
                 return .run { [backendAIClient, healthClient, modelContext] send in
                     // Start concurrent operations (Retry Logic)
                     async let aiResponseTask = Task {
                         let responseText = try await backendAIClient.generateResponse([], prompt, nil)
                         return ChatMessage(content: responseText, isFromCurrentUser: false)
                     }

                     async let healthMetricsTask = Task { () -> DailyMetrics in
                         let metricsArray = try await healthClient.fetchHealthMetrics()
                         let steps = metricsArray.first(where: { $0.type == .steps })?.value ?? 0.0
                         let energy = metricsArray.first(where: { $0.type == .calories })?.value ?? 0.0
                         let heartRate = metricsArray.first(where: { $0.type == .heartRate })?.value ?? 0.0
                         return DailyMetrics(steps: steps, activeEnergy: energy, heartRate: heartRate)
                     }

                     // Await results
                     do {
                         let aiMessage = try await aiResponseTask.value
                         let dailyMetrics = try await healthMetricsTask.value

                         // Save AI message locally
                         modelContext.context.insert(aiMessage)
                         try modelContext.context.save()
                         await send(.aiMessageSaved(.success(aiMessage)))

                         await send(.submissionDataLoaded(.success(dailyMetrics)))

                     } catch {
                         print("❌ Error during retry concurrent fetch/save: \(error)")
                         await send(.aiMessageSaved(.failure(error)))
                         await send(.submissionDataLoaded(.failure(error)))
                     }
                 }
             case .aiResponseReceived: // Should not happen if saves are handled first
                  print("Warning: aiResponseReceived hit directly")
                  state.isSendingMessage = false
                  return .none
             case .submissionDataLoaded(.success(let dailyMetrics)):
    // Calculate motion metrics
    let avgMotion = state.currentMotionData.reduce((0.0, 0.0, 0.0)) { 
        ($0.0 + $1.x, $0.1 + $1.y, $0.2 + $1.z) 
    }
    let count = Double(state.currentMotionData.count)
    let motionMetrics = DeviceMotionMetrics(
        avgAccelerationX: count > 0 ? avgMotion.0 / count : 0,
        avgAccelerationY: count > 0 ? avgMotion.1 / count : 0,
        avgAccelerationZ: count > 0 ? avgMotion.2 / count : 0
    )
    
    let typingMetrics = TypingMetrics(
        wordsPerMinute: state.currentWPM,
        totalEditCount: state.currentEditCountForSubmission
    )
    
    // NEW: Get user ID and submit to backend
    return .run { [dataSubmissionClient] _ in
        do {
            // Ensure user is registered first
            try await UserManager.shared.ensureUserRegistered()
            let userId = try await UserManager.shared.getCurrentUserId()
            try await dataSubmissionClient.submitMetrics(
                userId,
                dailyMetrics,
                typingMetrics,
                motionMetrics
            )
            print("✅ Successfully submitted metrics to backend")
        } catch {
            print("❌ Error submitting analytics data: \(error)")
        }
    }
             case .submissionDataLoaded(.failure(let error)):
                 print("Failed to load HealthKit data for submission: \(error)")
                 return .none
             case .alert:
                 return .none
                 
             // Voice Journaling Logic
             case .recordButtonTapped:
                 state.isRecording.toggle()
                 if state.isRecording {
                     return .run { [speechClient] send in
                         // Request permission first
                         let authStatus = await speechClient.requestAuthorization()
                         
                         guard authStatus == .authorized else {
                             await send(.speechError("Please enable Speech Recognition in Settings → Privacy → Speech Recognition"))
                             return
                         }
                         
                         let request = SFSpeechAudioBufferRecognitionRequest()
                         request.shouldReportPartialResults = true
                         
                         do {
                             for try await transcript in speechClient.startTask(request) {
                                 await send(.speechResult(transcript))
                             }
                         } catch {
                             await send(.speechError(error.localizedDescription))
                         }
                     }
                     .cancellable(id: CancelID.speech)
                 } else {
                     return .cancel(id: CancelID.speech)
                 }
                 
             case .speechResult(let transcript):
                 state.textInput = transcript
                 return .none
                 
             case .speechError(let errorMsg):
                 state.isRecording = false
                 state.alert = AlertState { TextState("Microphone Error") } message: { TextState(errorMsg) }
                 return .none
                 
             case .checkSpeechAuthorization:
                  return .none // Handled in task or on demand

            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

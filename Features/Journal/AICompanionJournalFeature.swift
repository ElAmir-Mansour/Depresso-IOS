// Features/Journal/AICompanionJournalFeature.swift
import Foundation
import ComposableArchitecture
import CoreMotion
import SwiftData
import SwiftUI
import Speech

@Reducer
struct AICompanionJournalFeature {
      private enum CancelID { 
          case motion 
          case speech
      }

      @ObservableState
      struct State: Equatable {
          static func == (lhs: AICompanionJournalFeature.State, rhs: AICompanionJournalFeature.State) -> Bool {
              return lhs.messages.map(\.id) == rhs.messages.map(\.id) &&
                     lhs.textInput == rhs.textInput &&
                     lhs.isSendingMessage == rhs.isSendingMessage &&
                     lhs.isRecording == rhs.isRecording &&
                     lhs.preDictationText == rhs.preDictationText
          }
          var messages: [ChatMessage] = []
          var textInput: String = ""
          var isSendingMessage: Bool = false
          @Presents var alert: AlertState<Action.Alert>?
          var journalSessionStartDate: Date?
          var editCount: Int = 0
          var motionSamples: [CMAcceleration] = []
          var currentWPM: Double = 0
          var currentSessionDuration: TimeInterval = 0
          var currentMotionData: [CMAcceleration] = []
          var currentEditCountForSubmission: Int = 0
          
          var isRecording: Bool = false
          var preDictationText: String = ""
          var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
          
          @Presents var destination: Destination.State?
      }

      enum Action: BindableAction {
          case binding(BindingAction<State>)
          case sendButtonTapped
          case quickPromptTapped(String)
          case deleteMessage(UUID)
          case aiResponseReceived(Result<ChatMessage, Error>)
          case alert(PresentationAction<Alert>)
          case task
          case motionUpdate(MotionData)
          case userDidBackspace
          case submissionDataLoaded(Result<DailyMetrics, Error>)
          case messagesLoaded(Result<[ChatMessage], Error>)
          case userMessageSaved(Result<ChatMessage, Error>)
          case aiMessageSaved(Result<ChatMessage, Error>)
          
          case recordButtonTapped
          case speechResult(String)
          case speechError(Error)

          case retryLastMessage
          case syncUnsyncedMessages
          case guidedJournalTemplateSelected(GuidedJournalFeature.CBTTemplate)
          case destination(PresentationAction<Destination.Action>)
          
          @CasePathable
          enum Alert: Equatable {
              case retry
          }
      }
      
      @Reducer(state: .equatable)
      enum Destination {
          case guidedJournal(GuidedJournalFeature)
      }


      @Dependency(\.aiClient) var aiClient
      @Dependency(\.motionClient) var motionClient
      @Dependency(\.speechClient) var speechClient
      @Dependency(\.healthClient) var healthClient
      @Dependency(\.dataSubmissionClient) var dataSubmissionClient
      @Dependency(\.uuid) var uuid
      @Dependency(\.modelContext) var modelContext

      private func history(from messages: [ChatMessage]) -> [AIModelContent] {
           return messages.map { message in
                let role = message.isFromCurrentUser ? "user" : "model"
                return AIModelContent(role: role, parts: [message.content])
           }
      }

    @MainActor
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
             case .task:
                // Strict fetch: wait for UserManager to have an ID
                let initialLoad = Effect<Action>.run { [modelContext] send in
                    // Polling/Waiting for ID if needed (for fresh logins)
                    var userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                    let maxRetries = 10
                    var retries = 0
                    
                    while userId.isEmpty && retries < maxRetries {
                        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5s
                        userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                        retries += 1
                    }
                    
                    guard !userId.isEmpty else { return }
                    
                    let currentId = userId
                    await MainActor.run {
                        let descriptor = FetchDescriptor<ChatMessage>(
                            predicate: #Predicate<ChatMessage> { $0.userId == currentId },
                            sortBy: [SortDescriptor(\.timestamp)]
                        )
                        if let messages = try? modelContext.context.fetch(descriptor) {
                            send(.messagesLoaded(.success(messages)))
                        }
                    }
                }
                
                let startMotion = Effect<Action>.run { [motionClient] send in
                    for await motionData in motionClient.start() {
                        await send(.motionUpdate(motionData))
                    }
                }
                .cancellable(id: CancelID.motion)
                
                return .merge(initialLoad, startMotion, .send(.syncUnsyncedMessages))
                
             case .syncUnsyncedMessages:
                let unsynced = state.messages.filter { $0.isFromCurrentUser && !$0.isSynced }
                guard !unsynced.isEmpty else { return .none }
                
                return .run { [aiClient, modelContext] send in
                    for message in unsynced {
                        do {
                            let responseText = try await aiClient.generateResponse([], message.content, nil)
                            await MainActor.run {
                                message.isSynced = true
                                let aiMessage = ChatMessage(userId: message.userId, content: responseText, isFromCurrentUser: false, isSynced: true)
                                modelContext.context.insert(aiMessage)
                                try? modelContext.context.save()
                                send(.aiMessageSaved(.success(aiMessage)))
                            }
                        } catch {
                            print("⚠️ Failed to sync message \(message.id): \(error)")
                        }
                    }
                }
                
             case .guidedJournalTemplateSelected(let template):
                state.destination = .guidedJournal(.init(template: template))
                return .none
                
             case .destination(.presented(.guidedJournal(.submissionCompleted(.success)))):
                state.destination = nil
                return .none
                
             case .destination:
                return .none

             case .messagesLoaded(.success(let messages)):
                 state.messages = messages
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

             case .deleteMessage(let id):
                 if let index = state.messages.firstIndex(where: { $0.id == id }) {
                     let message = state.messages[index]
                     state.messages.remove(at: index)
                     return .run { [modelContext] _ in
                         await MainActor.run {
                             modelContext.context.delete(message)
                             try? modelContext.context.save()
                         }
                     }
                 }
                 return .none

             case .quickPromptTapped(let prompt):
                 state.textInput = prompt
                 return .send(.sendButtonTapped)

            case .sendButtonTapped:
                guard !state.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }

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
                
                let history = self.history(from: state.messages)

                return .run { [modelContext, aiClient, healthClient] send in
                    let currentUserId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
                    
                    let userMessage = await MainActor.run {
                        let message = ChatMessage(userId: currentUserId, content: messageContent, isFromCurrentUser: true, isSynced: false)
                        modelContext.context.insert(message)
                        try? modelContext.context.save()
                        send(.userMessageSaved(.success(message)))
                        return message
                    }

                    do {
                        let responseText = try await aiClient.generateResponse(history, prompt, nil)
                        let metricsArray = try await healthClient.fetchHealthMetrics()
                        let steps = metricsArray.first(where: { $0.type == .steps })?.value ?? 0.0
                        let energy = metricsArray.first(where: { $0.type == .calories })?.value ?? 0.0
                        let heartRate = metricsArray.first(where: { $0.type == .heartRate })?.value ?? 0.0
                        let dailyMetrics = DailyMetrics(steps: steps, activeEnergy: energy, heartRate: heartRate)

                        await MainActor.run {
                            userMessage.isSynced = true
                            let aiMessage = ChatMessage(userId: currentUserId, content: responseText, isFromCurrentUser: false, isSynced: true)
                            modelContext.context.insert(aiMessage)
                            try? modelContext.context.save()
                            
                            Task {
                                await AchievementManager.shared.checkAchievements(userId: currentUserId, context: modelContext.context)
                            }
                            
                            send(.aiMessageSaved(.success(aiMessage)))
                        }

                        await send(.submissionDataLoaded(.success(dailyMetrics)))

                    } catch {
                        print("❌ Sync/AI Error: \(error)")
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
                 
                 let previousMessages = state.messages.dropLast(1).filter { $0.id != lastUserMessage.id }
                 let historyContext = self.history(from: Array(previousMessages))

                 return .run { [aiClient, healthClient, modelContext] send in
                     async let aiResponseTask = Task {
                         let responseText = try await aiClient.generateResponse(historyContext, prompt, nil)
                         return ChatMessage(userId: lastUserMessage.userId, content: responseText, isFromCurrentUser: false)
                     }

                     async let healthMetricsTask = Task { () -> DailyMetrics in
                         let metricsArray = try await healthClient.fetchHealthMetrics()
                         let steps = metricsArray.first(where: { $0.type == .steps })?.value ?? 0.0
                         let energy = metricsArray.first(where: { $0.type == .calories })?.value ?? 0.0
                         let heartRate = metricsArray.first(where: { $0.type == .heartRate })?.value ?? 0.0
                         return DailyMetrics(steps: steps, activeEnergy: energy, heartRate: heartRate)
                     }

                     do {
                         let aiMessage = try await aiResponseTask.value
                         let dailyMetrics = try await healthMetricsTask.value

                         await MainActor.run {
                             modelContext.context.insert(aiMessage)
                             try? modelContext.context.save()
                             send(.aiMessageSaved(.success(aiMessage)))
                         }

                         await send(.submissionDataLoaded(.success(dailyMetrics)))

                     } catch {
                         print("❌ Error during retry concurrent fetch/save: \(error)")
                         await send(.aiMessageSaved(.failure(error)))
                         await send(.submissionDataLoaded(.failure(error)))
                     }
                 }
             case .aiResponseReceived:
                  state.isSendingMessage = false
                  return .none
             case .submissionDataLoaded(.success(let dailyMetrics)):
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
                
                return .run { [dataSubmissionClient] _ in
                    do {
                        try await UserManager.shared.ensureUserRegistered()
                        let userId = try await UserManager.shared.getCurrentUserId()
                        try await dataSubmissionClient.submitMetrics(
                            userId,
                            dailyMetrics,
                            typingMetrics,
                            motionMetrics
                        )
                    } catch {
                        print("❌ Error submitting analytics data: \(error)")
                    }
                }
             case .submissionDataLoaded(.failure(let error)):
                 print("Failed to load HealthKit data for submission: \(error)")
                 return .none
             case .alert, .binding:
                 return .none
                 
             case .recordButtonTapped:
                 state.isRecording.toggle()
                 if state.isRecording {
                     state.preDictationText = state.textInput
                     return .run { [speechClient] send in
                         let authStatus = await speechClient.requestAuthorization()
                         
                         guard authStatus == .authorized else {
                             await send(.speechError(SpeechError.notAuthorized))
                             return
                         }
                         
                         let request = SFSpeechAudioBufferRecognitionRequest()
                         request.shouldReportPartialResults = true
                         
                         do {
                             for try await transcript in speechClient.startTask(request) {
                                 await send(.speechResult(transcript))
                             }
                         } catch {
                             await send(.speechError(error))
                         }
                     }
                     .cancellable(id: CancelID.speech)
                 } else {
                     return .cancel(id: CancelID.speech)
                 }
                 
             case .speechResult(let transcript):
                 let prefix = state.preDictationText.trimmingCharacters(in: .whitespacesAndNewlines)
                 if prefix.isEmpty {
                     state.textInput = transcript
                 } else {
                     state.textInput = "\(prefix) \(transcript)"
                 }
                 return .none
                 
             case .speechError(let error):
                 state.isRecording = false
                 state.alert = AlertState { TextState("Voice Entry Error") } message: { TextState(error.localizedDescription) }
                 return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }
}

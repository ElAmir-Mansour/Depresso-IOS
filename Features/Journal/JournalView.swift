// In Features/Journal/JournalView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct JournalView: View {
    @Bindable var store: StoreOf<AICompanionJournalFeature>
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.medium) {
                        if store.messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(groupedMessages.keys.sorted(), id: \.self) { date in
                                Section(header: dateHeader(date)) {
                                    ForEach(groupedMessages[date] ?? []) { message in
                                        MessageBubble(
                                            message: message,
                                            onDelete: {
                                                store.send(.deleteMessage(message.id))
                                            }
                                        )
                                        .id(message.id)
                                        .transition(.scale(scale: 0.95, anchor: message.isFromCurrentUser ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
                                    }
                                }
                            }
                        }
                        
                        if store.isSendingMessage {
                            TypingIndicator()
                                .id("typingIndicator")
                        }
                        
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.top, DesignSystem.Spacing.medium)
                }
                .background(Color.ds.backgroundPrimary)
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .onChange(of: store.messages.count) {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: isTextFieldFocused) {
                    if isTextFieldFocused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            scrollToBottom(scrollViewProxy)
                        }
                    }
                }
            }
            
            inputBar
                .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea(edges: .bottom))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        }
        .navigationTitle("Mindful Moments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        store.send(.guidedJournalTemplateSelected(GuidedJournalFeature.gratitudeTemplate))
                    } label: {
                        Label("Gratitude & Joy", systemImage: "heart.text.square")
                    }
                    
                    Button {
                        store.send(.guidedJournalTemplateSelected(GuidedJournalFeature.thoughtRecordTemplate))
                    } label: {
                        Label("Thought Record", systemImage: "brain.head.profile")
                    }
                } label: {
                    Image(systemName: "sparkles")
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.destination?.guidedJournal, action: \.destination.guidedJournal)) { guidedStore in
            GuidedJournalView(store: guidedStore)
        }
        .task {
            store.send(.task)
        }
    }
    
    private var groupedMessages: [Date: [ChatMessage]] {
        Dictionary(grouping: store.messages) { message in
            Calendar.current.startOfDay(for: message.timestamp)
        }
    }
    
    private func dateHeader(_ date: Date) -> some View {
        Text(headerTitle(for: date))
            .font(.ds.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 8)
    }
    
    private func headerTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)
            
            DSIcon(DSIcons.successState, size: 140)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            
            VStack(spacing: 12) {
                Text("How are you feeling today?")
                    .font(.ds.title3)
                    .foregroundStyle(Color.ds.textPrimary)
                
                Text("Your morning brew is ready. Share your thoughts, or choose a prompt to start.")
                    .font(.ds.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                quickPromptButton(title: "😊 Good day", prompt: "I'm having a good day because...")
                quickPromptButton(title: "😔 Struggling", prompt: "I'm having a tough time with...")
                quickPromptButton(title: "💭 Reflective", prompt: "I've been thinking about...")
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }
    
    private func quickPromptButton(title: String, prompt: String) -> some View {
        Button {
            store.send(.quickPromptTapped(prompt))
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.ds.accent)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.ds.accent.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.ds.accent.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            if store.isRecording {
                HStack {
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
                        .foregroundStyle(.red)
                    Text("Listening...")
                        .font(.ds.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack(spacing: 12) {
                TextField("Type your thoughts...", text: $store.textInput, axis: .vertical)
                    .padding(12)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.ds.border, lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)
                    .lineLimit(1...6)
                    .frame(minHeight: 44)
                
                Button {
                    DSHaptics.buttonPress()
                    store.send(.recordButtonTapped)
                } label: {
                    Image(systemName: store.isRecording ? "stop.fill" : "mic.fill")
                        .font(.headline)
                        .foregroundStyle(store.isRecording ? .white : .secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(store.isRecording ? Color.red : Color(UIColor.systemBackground))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.red.opacity(0.5), lineWidth: store.isRecording ? 4 : 0)
                                .scaleEffect(store.isRecording ? 1.5 : 1)
                                .opacity(store.isRecording ? 0 : 1)
                                .animation(store.isRecording ? .easeOut(duration: 1).repeatForever(autoreverses: false) : .default, value: store.isRecording)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }

                Button {
                    DSHaptics.buttonPress()
                    store.send(.sendButtonTapped)
                    isTextFieldFocused = false
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(store.textInput.isEmpty ? Color.gray.opacity(0.5) : Color.ds.accent)
                        )
                        .shadow(color: store.textInput.isEmpty ? .clear : Color.ds.accent.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .disabled(store.textInput.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if !isTextFieldFocused {
                Color.clear.frame(height: 80)
            }
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.25)) {
                if store.isSendingMessage {
                    proxy.scrollTo("typingIndicator", anchor: .bottom)
                } else if let lastMessage = store.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: ChatMessage.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    let messages = [
        ChatMessage(userId: "preview_user", content: "Hello! How are you feeling today?", isFromCurrentUser: false),
        ChatMessage(userId: "preview_user", content: "I've been feeling a bit overwhelmed.", isFromCurrentUser: true)
    ]
    
    let _ = messages.forEach { context.insert($0) }
    
    let store = Store(initialState: AICompanionJournalFeature.State(messages: messages)) {
        AICompanionJournalFeature()
            .dependency(\.modelContext, try! ModelContextBox(context))
    }
    
    NavigationStack {
        JournalView(store: store)
            .modelContainer(container)
    }
}

// In Features/Journal/JournalView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct JournalView: View {
    @Bindable var store: StoreOf<AICompanionJournalFeature>
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages ScrollView
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.medium) {
                        if store.messages.isEmpty {
                            VStack(spacing: 24) { // Increased spacing
                                Spacer(minLength: 120)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.ds.accent.opacity(0.08))
                                        .frame(width: 140, height: 140)
                                    
                                    Circle()
                                        .fill(Color.ds.accent.opacity(0.15))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "sun.haze.fill") // Softer icon
                                        .font(.system(size: 48))
                                        .foregroundStyle(Color.ds.accent.gradient)
                                }
                                
                                VStack(spacing: 12) {
                                    Text("How are you feeling today?")
                                        .font(.ds.title3)
                                        .foregroundStyle(Color.ds.textPrimary)
                                    
                                    Text("I'm here to listen. Share your thoughts, or just vent. Everything stays between us.")
                                        .font(.ds.body)
                                        .foregroundStyle(Color.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .transition(.opacity)
                        } else {
                            ForEach(store.messages) { message in
                                MessageBubble(message: message)
                                   .id(message.id)
                                   .transition(.scale(scale: 0.95, anchor: message.isFromCurrentUser ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
                            }
                        }
                        
                        if store.isSendingMessage {
                            TypingIndicator()
                                .id("typingIndicator")
                        }
                        
                        // Extra padding at bottom for input bar content
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
            
            // Input bar - fixed at bottom
            inputBar
                .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea(edges: .bottom))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4) // Subtle shadow
        }
        .navigationTitle("Mindful Moments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        store.send(.guidedJournalButtonTapped)
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    
                    if isTextFieldFocused {
                        Button("Done") {
                            isTextFieldFocused = false
                        }
                    }
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
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            // Removed hard divider for cleaner look
            
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
                
                // Microphone Button
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
                            Circle() // Ripple effect
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
            
            // Filler for Tab Bar (only when keyboard is NOT focused)
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

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
                            VStack(spacing: 20) {
                                Spacer(minLength: 100)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.ds.accent.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(Color.orange.opacity(0.8))
                                }
                                
                                VStack(spacing: 8) {
                                    Text("How are you feeling?")
                                        .font(.system(.title2, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Color.primary)
                                    
                                    Text("I'm here to listen. Share your thoughts...")
                                        .font(.body)
                                        .foregroundStyle(Color.secondary)
                                        .multilineTextAlignment(.center)
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
                        
                        // Extra padding at bottom for input bar
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.top, DesignSystem.Spacing.small)
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
                .background(.ultraThinMaterial)
        }
        .navigationTitle("Mindful Moments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isTextFieldFocused {
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .task {
            store.send(.task)
        }
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.systemGray4))
            
            HStack(spacing: 12) {
                TextField("How are you feeling...", text: $store.textInput, axis: .vertical)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isTextFieldFocused)
                    .lineLimit(1...6)
                    .frame(minHeight: 44)
                
                // Microphone Button
                Button {
                    DSHaptics.buttonPress()
                    store.send(.recordButtonTapped)
                } label: {
                    Image(systemName: store.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title3)
                        .foregroundStyle(store.isRecording ? .red : .secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            Group {
                                if store.isRecording {
                                    Circle()
                                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                        .scaleEffect(1.2)
                                        .opacity(0)
                                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: store.isRecording)
                                }
                            }
                        )
                }

                Button {
                    DSHaptics.buttonPress()
                    store.send(.sendButtonTapped)
                    isTextFieldFocused = false
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(store.textInput.isEmpty ? Color.gray : Color.accentColor)
                        )
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

import SwiftUI
import ComposableArchitecture

struct EnhancedGoalsView: View {
    @Bindable var store: StoreOf<WellnessTasksFeature>
    @State private var showAddGoal = false
    
    var completionPercentage: Double {
        guard !store.tasks.isEmpty else { return 0 }
        let completed = store.tasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(store.tasks.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            headerSection
            
            // Goals list
            if store.tasks.isEmpty {
                emptyStateView
            } else {
                goalsListSection
            }
            
            // Add button
            addGoalButton
        }
        .background(Color.ds.backgroundPrimary)
        .onAppear {
            if store.tasks.isEmpty {
                store.send(.task)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Goals")
                        .font(.ds.title2)
                        .fontWeight(.bold)
                    
                    Text("\(store.tasks.filter { $0.isCompleted }.count) of \(store.tasks.count) completed")
                        .font(.ds.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.ds.border, lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: completionPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [Color.ds.accent, Color.ds.accentDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: completionPercentage)
                    
                    Text("\(Int(completionPercentage * 100))%")
                        .font(.ds.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.ds.accent)
                }
                .frame(width: 50, height: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.ds.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        )
    }
    
    private var goalsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.tasks) { task in
                    EnhancedGoalRow(
                        task: task,
                        onToggle: { store.send(.toggleTaskCompletion(id: task.id)) },
                        onDelete: {
                            if let index = store.tasks.firstIndex(where: { $0.id == task.id }) {
                                store.send(.deleteTask(IndexSet(integer: index)))
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ds.accent.opacity(0.6), Color.ds.accentDark.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("No goals yet")
                    .font(.ds.title3)
                    .fontWeight(.semibold)
                
                Text("Set your first daily goal and\nstart building better habits")
                    .font(.ds.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    private var addGoalButton: some View {
        Button {
            showAddGoal = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                
                Text("Add New Goal")
                    .font(.ds.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.ds.accent, Color.ds.accentDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.ds.accent.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(store: store)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct EnhancedGoalRow: View {
    let task: WellnessTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteButton = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? 
                            Color.ds.accent :
                            Color.ds.border
                        )
                        .frame(width: 28, height: 28)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task title
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.ds.body)
                    .fontWeight(.medium)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                
                if task.isCompleted {
                    Text("Completed")
                        .font(.ds.caption2)
                        .foregroundStyle(Color.ds.accent)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(showDeleteButton ? 1 : 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ds.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(task.isCompleted ? Color.ds.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(task.isCompleted ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.isCompleted)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            showDeleteButton.toggle()
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
        }
    }
}

struct AddGoalSheet: View {
    @Bindable var store: StoreOf<WellnessTasksFeature>
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ds.accent, Color.ds.accentDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Add New Goal")
                        .font(.ds.title3)
                        .fontWeight(.bold)
                }
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your goal?")
                        .font(.ds.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., Drink 8 glasses of water", text: $store.newTaskTitle)
                        .font(.ds.body)
                        .padding(16)
                        .background(Color.ds.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isTextFieldFocused)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.ds.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.ds.backgroundSecondary)
                            .foregroundStyle(Color.ds.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        store.send(.addTaskButtonTapped)
                        dismiss()
                    } label: {
                        Text("Add Goal")
                            .font(.ds.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.ds.accent, Color.ds.accentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(store.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(store.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.ds.backgroundPrimary)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

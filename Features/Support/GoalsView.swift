// Features/Support/GoalsView.swift
import SwiftUI

struct Goal: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
    var progress: Double
    let target: Int
    let current: Int
    let unit: String
}

struct GoalsView: View {
    @State private var goals: [Goal] = [
        Goal(
            title: "Daily Check-ins",
            description: "Complete your daily mood tracking",
            iconName: "checkmark.circle.fill",
            color: .blue,
            progress: 0.7,
            target: 7,
            current: 5,
            unit: "days"
        ),
        Goal(
            title: "Journal Entries",
            description: "Express your thoughts and feelings",
            iconName: "book.fill",
            color: .purple,
            progress: 0.4,
            target: 10,
            current: 4,
            unit: "entries"
        ),
        Goal(
            title: "Active Minutes",
            description: "Stay physically active",
            iconName: "figure.walk",
            color: .green,
            progress: 0.6,
            target: 150,
            current: 90,
            unit: "minutes"
        ),
        Goal(
            title: "Sleep Quality",
            description: "Maintain healthy sleep patterns",
            iconName: "bed.double.fill",
            color: .indigo,
            progress: 0.85,
            target: 8,
            current: 7,
            unit: "hours"
        ),
        Goal(
            title: "Community Engagement",
            description: "Connect with the community",
            iconName: "person.3.fill",
            color: .orange,
            progress: 0.3,
            target: 5,
            current: 2,
            unit: "interactions"
        )
    ]
    
    @State private var selectedGoal: Goal?
    @State private var showAddGoal = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly Summary Card
                    weeklySummaryCard
                    
                    // Goals Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Your Goals")
                                .font(.system(size: 24, weight: .bold))
                            
                            Spacer()
                            
                            Button {
                                showAddGoal = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(goals) { goal in
                                GoalCard(goal: goal)
                                    .onTapGesture {
                                        selectedGoal = goal
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Motivational Quote
                    motivationalCard
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Wellness Goals")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalView()
            }
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Great Progress!")
                        .font(.system(size: 24, weight: .bold))
                }
                
                Spacer()
                
                // Achievement badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            // Overall progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Completion")
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text("62%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: 0.62)
                    .tint(.blue)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    private var motivationalCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("\"Small steps every day lead to big changes over time.\"")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.1),
                            Color.pink.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal, 20)
    }
}

struct GoalCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(goal.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: goal.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(goal.color)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text(goal.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(goal.current) / \(goal.target) \(goal.unit)")
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(goal.color)
                }
                
                // Custom progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(goal.color.opacity(0.15))
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [goal.color, goal.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * goal.progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct GoalDetailView: View {
    let goal: Goal
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [goal.color.opacity(0.3), goal.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: goal.iconName)
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(goal.color)
                    }
                    .padding(.top, 20)
                    
                    // Stats
                    VStack(spacing: 16) {
                        Text(goal.title)
                            .font(.system(size: 28, weight: .bold))
                        
                        Text(goal.description)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Progress
                        VStack(spacing: 12) {
                            Text("\(Int(goal.progress * 100))% Complete")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(goal.color)
                            
                            Text("\(goal.current) of \(goal.target) \(goal.unit)")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var goalTitle = ""
    @State private var goalDescription = ""
    @State private var target = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Information") {
                    TextField("Goal Title", text: $goalTitle)
                    TextField("Description", text: $goalDescription)
                    TextField("Target", text: $target)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        // Add goal logic here
                        dismiss()
                    }
                    .disabled(goalTitle.isEmpty)
                }
            }
        }
    }
}

#Preview {
    GoalsView()
}

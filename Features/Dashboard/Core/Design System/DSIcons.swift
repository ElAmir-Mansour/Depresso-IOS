import SwiftUI

// Advanced icon system with GitHub Octicons-inspired design
enum DSIcons {
    // Health & Metrics (Octicons style)
    static let heart = "heart.fill"
    static let heartbeat = "waveform.path.ecg.rectangle.fill"
    static let steps = "figure.walk.circle.fill"
    static let sleep = "bed.double.fill"
    static let energy = "bolt.circle.fill"
    static let activity = "flame.circle.fill"
    static let mood = "face.smiling.fill"
    
    // Progress & Stats
    static let chart = "chart.bar.fill"
    static let chartLine = "chart.line.uptrend.xyaxis"
    static let calendar = "calendar.circle.fill"
    static let checkmark = "checkmark.seal.fill"
    static let trophy = "trophy.circle.fill"
    static let star = "star.circle.fill"
    static let target = "scope"
    
    // Navigation (Tab Bar)
    static let home = "squares.below.rectangle"
    static let journal = "book.closed.fill"
    static let community = "person.3.sequence.fill"
    static let support = "heart.text.square.fill"
    static let settings = "gearshape.2.fill"
    
    // Actions
    static let plus = "plus.circle.fill"
    static let plusSquare = "plus.square.fill"
    static let refresh = "arrow.triangle.2.circlepath.circle.fill"
    static let info = "info.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let bell = "bell.badge.fill"
    static let share = "square.and.arrow.up.circle.fill"
    
    // Wellness & Mental Health
    static let brain = "brain.head.profile"
    static let meditation = "sparkles"
    static let water = "drop.circle.fill"
    static let sun = "sun.max.circle.fill"
    static let moon = "moon.circle.fill"
    static let leaf = "leaf.circle.fill"
    
    // Streak & Progress
    static let fire = "flame.fill"
    static let streak = "arrow.up.right.circle.fill"
    static let progress = "chart.pie.fill"
    
    // AI & Insights
    static let ai = "sparkle.magnifyingglass"
    static let insights = "lightbulb.fill"
    static let robot = "brain"
}

// Advanced icon view with animations and effects
struct DSIcon: View {
    let name: String
    let color: Color
    let size: CGFloat
    let weight: Font.Weight
    let animated: Bool
    
    @State private var isAnimating = false
    
    init(
        _ name: String, 
        color: Color = .primary, 
        size: CGFloat = 20,
        weight: Font.Weight = .semibold,
        animated: Bool = false
    ) {
        self.name = name
        self.color = color
        self.size = size
        self.weight = weight
        self.animated = animated
    }
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: weight, design: .rounded))
            .foregroundStyle(color.gradient)
            .symbolRenderingMode(.hierarchical)
            .scaleEffect(isAnimating && animated ? 1.1 : 1.0)
            .animation(
                animated ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : nil,
                value: isAnimating
            )
            .onAppear {
                if animated {
                    isAnimating = true
                }
            }
    }
}

// Gradient icon for premium look
struct DSGradientIcon: View {
    let name: String
    let gradient: LinearGradient
    let size: CGFloat
    
    init(_ name: String, gradient: LinearGradient, size: CGFloat = 24) {
        self.name = name
        self.gradient = gradient
        self.size = size
    }
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(gradient)
            .symbolRenderingMode(.hierarchical)
    }
}

// Animated badge icon
struct DSBadgeIcon: View {
    let name: String
    let badgeCount: Int?
    let color: Color
    let size: CGFloat
    
    init(_ name: String, badge: Int? = nil, color: Color = .ds.accent, size: CGFloat = 24) {
        self.name = name
        self.badgeCount = badge
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            DSIcon(name, color: color, size: size)
            
            if let count = badgeCount, count > 0 {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

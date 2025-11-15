import SwiftUI

// Custom animated tab bar with modern design
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    let tabs: [TabItem] = [
        TabItem(icon: "chart.line.uptrend.xyaxis", title: "Dashboard", index: 0),
        TabItem(icon: "book.pages.fill", title: "Journal", index: 1),
        TabItem(icon: "person.3.fill", title: "Community", index: 2),
        TabItem(icon: "heart.text.square.fill", title: "Support", index: 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab.index,
                    namespace: animation
                ) {
                    DSHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.index
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tabBarBackground)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
    
    private var tabBarBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 30, y: 15)
    }
}

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.ds.accent.opacity(0.15))
                            .matchedGeometryEffect(id: "TAB_BACKGROUND", in: namespace)
                            .frame(width: 64, height: 40)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .ds.accent : .secondary)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(height: 40)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .ds.accent : .secondary)
                    .opacity(isSelected ? 1.0 : 0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct TabItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let index: Int
}

// Floating tab bar container
struct FloatingTabBarContainer<Content: View>: View {
    @Binding var selectedTab: Int
    let content: Content
    
    init(selectedTab: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(0))
    }
}

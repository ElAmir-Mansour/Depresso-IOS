// Features/OnBoarding/WelcomeOnboardingView.swift
import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let gradient: [Color]
}

struct WelcomeOnboardingView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    let onComplete: () -> Void
    let onSignIn: () -> Void
    
    // Reduced to 3 pages as per UX recommendations
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track Your Wellness",
            description: "Monitor your mental health with daily check-ins and understand patterns in your wellbeing.",
            iconName: "chart.line.uptrend.xyaxis",
            gradient: [Color.blue, Color.purple]
        ),
        OnboardingPage(
            title: "AI Insights",
            description: "Receive personalized recommendations powered by AI to support your mental health journey.",
            iconName: "brain.head.profile",
            gradient: [Color.purple, Color.blue]
        ),
        OnboardingPage(
            title: "Private Community",
            description: "Connect with others and share experiences in a safe, anonymous environment.",
            iconName: "person.3.fill",
            gradient: [Color.green, Color.teal]
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].gradient + [Color.black.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip Tour") {
                        onComplete()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
                .padding()
                
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        VStack(spacing: 40) {
                            ZStack {
                                Circle()
                                    .fill(RadialGradient(colors: [Color.white.opacity(0.3), Color.clear], center: .center, startRadius: 50, endRadius: 100))
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                                    .opacity(isAnimating ? 0.5 : 0.8)
                                
                                ZStack {
                                    Circle().fill(Color.white.opacity(0.2)).frame(width: 140, height: 140).blur(radius: 10)
                                    Circle().fill(Color.white).frame(width: 120, height: 120)
                                    Image(systemName: page.iconName)
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                            }
                            
                            VStack(spacing: 20) {
                                Text(page.title)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text(page.description)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                                    .padding(.horizontal, 30)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)
                
                Spacer()
                
                VStack(spacing: 30) {
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(currentPage == index ? 1.0 : 0.4))
                                .frame(width: currentPage == index ? 30 : 10, height: 10)
                        }
                    }
                    
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            onComplete()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Finish")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(pages[currentPage].gradient[0])
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

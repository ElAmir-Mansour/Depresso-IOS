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
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track Your Wellness",
            description: "Monitor your mental health with daily check-ins and mood tracking. Understand patterns in your emotional wellbeing.",
            iconName: "chart.line.uptrend.xyaxis",
            gradient: [Color.blue, Color.purple]
        ),
        OnboardingPage(
            title: "Health Integration",
            description: "Connect with Apple Health to track sleep, activity, and heart rate. Get holistic insights into your wellbeing.",
            iconName: "heart.text.square.fill",
            gradient: [Color.pink, Color.orange]
        ),
        OnboardingPage(
            title: "AI-Powered Insights",
            description: "Receive personalized recommendations and insights powered by advanced AI to support your mental health journey.",
            iconName: "brain.head.profile",
            gradient: [Color.purple, Color.blue]
        ),
        OnboardingPage(
            title: "Supportive Community",
            description: "Connect with others, share experiences, and find support in a safe, anonymous community environment.",
            iconName: "person.3.fill",
            gradient: [Color.green, Color.teal]
        ),
        OnboardingPage(
            title: "Your Privacy Matters",
            description: "Your data is encrypted and secure. You control what you share and what stays private. Your wellbeing, your way.",
            iconName: "lock.shield.fill",
            gradient: [Color.indigo, Color.cyan]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: pages[currentPage].gradient + [Color.black.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            currentPage = pages.count - 1
                        }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .opacity(currentPage < pages.count - 1 ? 1 : 0)
                }
                .padding()
                
                Spacer()
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        VStack(spacing: 40) {
                            // Icon with animated glow
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 50,
                                            endRadius: 100
                                        )
                                    )
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                                    .opacity(isAnimating ? 0.5 : 0.8)
                                
                                // Icon container
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 140, height: 140)
                                        .blur(radius: 10)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: page.iconName)
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: page.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .padding(.top, 40)
                            
                            // Text content
                            VStack(spacing: 20) {
                                Text(page.title)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                                
                                Text(page.description)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                                    .padding(.horizontal, 30)
                                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)
                
                Spacer()
                
                // Page indicator and button
                VStack(spacing: 30) {
                    // Custom page indicator
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(currentPage == index ? 1.0 : 0.4))
                                .frame(width: currentPage == index ? 30 : 10, height: 10)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(pages[currentPage].gradient[0])
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
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

// Preview
#Preview {
    WelcomeOnboardingView(onComplete: {
        print("Onboarding completed")
    })
}

// Features/Dashboard/Core/Design System/Components/DSSkeletonView.swift
import SwiftUI

// MARK: - Skeleton View

struct DSSkeletonView: View {
    var height: CGFloat = 120
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.large
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.15))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 400 : -400)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Text Line

struct DSSkeletonText: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.15))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Circle (for avatars)

struct DSSkeletonCircle: View {
    var size: CGFloat = 40
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? size * 2 : -size * 2)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Pre-built Skeleton Components

/// Skeleton for health metric card
struct DSSkeletonHealthCard: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            DSSkeletonCircle(size: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                DSSkeletonText(width: 100, height: 14)
                DSSkeletonText(width: 60, height: 20)
            }
            
            Spacer()
        }
        .padding()
        .cardStyle(.flat)
    }
}

/// Skeleton for community post
struct DSSkeletonPost: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                DSSkeletonCircle(size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    DSSkeletonText(width: 120, height: 14)
                    DSSkeletonText(width: 80, height: 12)
                }
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                DSSkeletonText(height: 12)
                DSSkeletonText(width: 250, height: 12)
                DSSkeletonText(width: 180, height: 12)
            }
            
            // Footer
            HStack(spacing: 16) {
                DSSkeletonText(width: 60, height: 12)
                DSSkeletonText(width: 80, height: 12)
                Spacer()
            }
        }
        .padding()
        .cardStyle(.flat)
    }
}

/// Skeleton for list item
struct DSSkeletonListItem: View {
    var body: some View {
        HStack(spacing: 12) {
            DSSkeletonCircle(size: 44)
            
            VStack(alignment: .leading, spacing: 6) {
                DSSkeletonText(width: 150, height: 14)
                DSSkeletonText(width: 100, height: 12)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Convenience View Extension

extension View {
    /// Show skeleton while loading
    @ViewBuilder
    func skeleton(
        isLoading: Bool,
        @ViewBuilder skeleton: () -> some View
    ) -> some View {
        if isLoading {
            skeleton()
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Basic Skeletons")
                .font(.ds.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DSSkeletonView(height: 100)
            DSSkeletonText(width: 200)
            DSSkeletonCircle()
            
            Divider()
            
            Text("Pre-built Components")
                .font(.ds.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DSSkeletonHealthCard()
            DSSkeletonPost()
            DSSkeletonListItem()
            
            Divider()
            
            Text("Usage with Content")
                .font(.ds.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Example of toggling
            Group {
                Text("Loaded Content")
                    .padding()
                    .cardStyle()
            }
            .skeleton(isLoading: false) {
                DSSkeletonView(height: 60)
            }
        }
        .padding()
    }
    .background(Color.ds.backgroundPrimary)
}

// MARK: - Usage Examples

/*
 
 // Simple skeleton card
 if store.isLoading {
     DSSkeletonView()
 } else {
     HealthCard(data: store.data)
 }
 
 // Multiple skeletons
 if store.isLoading {
     VStack(spacing: 16) {
         DSSkeletonHealthCard()
         DSSkeletonHealthCard()
         DSSkeletonHealthCard()
     }
 } else {
     HealthMetrics(data: store.metrics)
 }
 
 // Community posts
 if store.isLoadingPosts {
     ForEach(0..<3, id: \.self) { _ in
         DSSkeletonPost()
     }
 } else {
     ForEach(store.posts) { post in
         PostCard(post: post)
     }
 }
 
 // Using convenience modifier
 HealthCard(data: store.data)
     .skeleton(isLoading: store.isLoading) {
         DSSkeletonHealthCard()
     }
 
 */

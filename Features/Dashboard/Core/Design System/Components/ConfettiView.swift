// Features/Dashboard/Core/Design System/Components/ConfettiView.swift
import SwiftUI

struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(confetti) { piece in
                    ConfettiShape()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(x: piece.x, y: piece.y)
                        .rotationEffect(.degrees(piece.rotation))
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                createConfetti(in: geo.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private func createConfetti(in size: CGSize) {
        let pieceCount = 50
        
        for _ in 0..<pieceCount {
            let piece = ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                targetY: size.height + 100,
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 8...15),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            confetti.append(piece)
            
            // Animate each piece
            withAnimation(
                .linear(duration: Double.random(in: 2...4))
                .delay(Double.random(in: 0...0.5))
            ) {
                if let index = confetti.firstIndex(where: { $0.id == piece.id }) {
                    confetti[index].y = piece.targetY
                    confetti[index].rotation += Double.random(in: 360...720)
                    confetti[index].opacity = 0
                }
            }
        }
        
        // Remove confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            confetti.removeAll()
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let targetY: CGFloat
    let color: Color
    let size: CGFloat
    var rotation: Double
    var opacity: Double
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        return path
    }
}

// Star-shaped confetti variant
struct StarConfetti: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let points = 5
        
        for i in 0..<points * 2 {
            let angle = Double(i) * .pi / Double(points)
            let length = i % 2 == 0 ? radius : radius * 0.5
            let x = center.x + length * CGFloat(cos(angle - .pi / 2))
            let y = center.y + length * CGFloat(sin(angle - .pi / 2))
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Text("🎉 Celebration! 🎉")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        
        ConfettiView()
    }
}

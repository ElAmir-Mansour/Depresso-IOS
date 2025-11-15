// Features/Dashboard/Core/Design System/Components/DSHaptics.swift
import UIKit

/// Centralized haptic feedback system
enum DSHaptics {
    
    // MARK: - Impact Feedback
    
    /// Light impact - for subtle interactions like taps
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Medium impact - for standard button presses
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Heavy impact - for important actions
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    /// Soft impact - iOS 13+ only
    @available(iOS 13.0, *)
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    
    /// Rigid impact - iOS 13+ only
    @available(iOS 13.0, *)
    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification - for completed actions
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Warning notification - for attention-needed situations
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    /// Error notification - for failed actions
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed - for picker wheels, segmented controls
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    // MARK: - Convenience Methods
    
    /// Tap feedback - light impact for general taps
    static func tap() {
        light()
    }
    
    /// Button press - medium impact for buttons
    static func buttonPress() {
        medium()
    }
    
    /// Toggle - soft/light impact for switches and toggles
    static func toggle() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
    }
    
    /// Delete action - warning + medium impact
    static func delete() {
        warning()
    }
    
    /// Completion - success feedback
    static func complete() {
        success()
    }
    
    /// Failed action - error feedback
    static func fail() {
        error()
    }
}

// MARK: - View Extension for Easy Usage

import SwiftUI

extension View {
    /// Add haptic feedback to any view's tap gesture
    func hapticTap(_ style: DSHaptics.TapStyle = .light) -> some View {
        self.onTapGesture {
            switch style {
            case .light: DSHaptics.light()
            case .medium: DSHaptics.medium()
            case .heavy: DSHaptics.heavy()
            }
        }
    }
}

extension DSHaptics {
    enum TapStyle {
        case light, medium, heavy
    }
}

// MARK: - Usage Examples

/*
 
 // In a button action:
 Button("Send") {
     DSHaptics.buttonPress()
     viewModel.sendMessage()
 }
 
 // On successful completion:
 if success {
     DSHaptics.success()
 }
 
 // On error:
 catch {
     DSHaptics.error()
 }
 
 // For toggle:
 Toggle("Enable") { isOn in
     DSHaptics.toggle()
     setting = isOn
 }
 
 // For deletion:
 Button("Delete") {
     DSHaptics.delete()
     delete()
 }
 
 // Using view extension:
 Text("Tap me")
     .hapticTap(.medium)
 
 */

// Features/Dashboard/Core/Design System/Components/DSSyncIndicator.swift
import SwiftUI

struct DSSyncIndicator: View {
    let status: SyncStatus
    let lastSyncTime: Date?
    var onRetry: (() -> Void)?
    
    enum SyncStatus: Equatable {
        case synced
        case syncing
        case failed
        case offline
    }
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
            
            if status == .failed, let onRetry = onRetry {
                Button {
                    DSHaptics.light()
                    onRetry()
                } label: {
                    Text("Retry")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.ds.accent)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusBackgroundColor)
        .clipShape(Capsule())
    }
    
    private var statusIcon: some View {
        Group {
            switch status {
            case .synced:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .symbolEffect(.bounce, value: status)
            case .syncing:
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(Color.ds.accent)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.ds.error)
            case .offline:
                Image(systemName: "wifi.slash")
                    .foregroundStyle(Color.ds.warning)
            }
        }
        .font(.system(size: 16, weight: .semibold))
    }
    

    
    private var statusBackgroundColor: Color {
        switch status {
        case .synced:
            return Color.clear
        case .syncing:
            return Color.ds.accentLight.opacity(0.5)
        case .failed:
            return Color.ds.errorBackground
        case .offline:
            return Color.ds.warningBackground
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DSSyncIndicator(status: .synced, lastSyncTime: Date().addingTimeInterval(-120))
        DSSyncIndicator(status: .syncing, lastSyncTime: nil)
        DSSyncIndicator(status: .failed, lastSyncTime: nil, onRetry: {})
        DSSyncIndicator(status: .offline, lastSyncTime: nil)
    }
    .padding()
}

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
        HStack(spacing: 6) {
            statusIcon
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(statusColor)
            
            if status == .failed, let onRetry = onRetry {
                Button {
                    onRetry()
                } label: {
                    Text("Retry")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.ds.accent)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusBackgroundColor)
        .clipShape(Capsule())
    }
    
    private var statusIcon: some View {
        Group {
            switch status {
            case .synced:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.ds.success)
            case .syncing:
                ProgressView()
                    .scaleEffect(0.7)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.ds.error)
            case .offline:
                Image(systemName: "wifi.slash")
                    .foregroundStyle(Color.ds.warning)
            }
        }
        .font(.caption)
    }
    
    private var statusText: String {
        switch status {
        case .synced:
            if let lastSyncTime = lastSyncTime {
                return "Synced \(timeAgo(lastSyncTime))"
            }
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .failed:
            return "Sync failed"
        case .offline:
            return "Offline"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .synced:
            return Color.ds.textSecondary
        case .syncing:
            return Color.ds.textSecondary
        case .failed:
            return Color.ds.error
        case .offline:
            return Color.ds.warning
        }
    }
    
    private var statusBackgroundColor: Color {
        switch status {
        case .synced:
            return Color.ds.successBackground
        case .syncing:
            return Color.ds.accentLight
        case .failed:
            return Color.ds.errorBackground
        case .offline:
            return Color.ds.warningBackground
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
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

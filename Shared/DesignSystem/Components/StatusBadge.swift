import SwiftUI

struct StatusBadge: View {
    let status: ReminderStatus

    var body: some View {
        HStack(spacing: ICareSpacing.xs) {
            Image(systemName: iconName)
                .font(.system(size: 10))
            Text(label)
                .font(ICareTypography.caption)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, ICareSpacing.sm)
        .padding(.vertical, ICareSpacing.xs)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch status {
        case .active: "circle.fill"
        case .paused: "pause.circle"
        case .blocked: "exclamationmark.triangle"
        case .inactive: "circle"
        }
    }

    private var label: String {
        switch status {
        case .active: "Active"
        case .paused: "Paused"
        case .blocked: "Notifications Off"
        case .inactive: "Inactive"
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .active: ICareColors.brand
        case .paused: ICareColors.statusPaused
        case .blocked: ICareColors.statusBlocked
        case .inactive: ICareColors.textTertiary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .active: ICareColors.brandMuted
        case .paused: ICareColors.statusPaused.opacity(0.12)
        case .blocked: ICareColors.statusBlocked.opacity(0.12)
        case .inactive: ICareColors.separator
        }
    }
}

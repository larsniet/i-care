import SwiftUI
import UIKit

struct HomeBlockedContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ICareSpacing.lg) {
            HStack(alignment: .center, spacing: ICareSpacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .font(ICareTypography.callout)
                Text("Notifications are off")
                    .font(ICareTypography.subhead)
                    .fontWeight(.medium)
            }
            .foregroundStyle(ICareColors.statusBlocked)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ICareSpacing.base)
            .background(ICareColors.statusBlocked.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))

            Text("i care needs notifications to remind you about breaks. Enable them in Settings.")
                .font(ICareTypography.body)
                .foregroundStyle(ICareColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            PrimaryButton(title: "Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            HomeActiveContent()
                .opacity(0.42)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ICareSpacing.base)
    }
}

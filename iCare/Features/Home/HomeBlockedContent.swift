import SwiftUI
import UIKit

struct HomeBlockedContent: View {
    @EnvironmentObject private var appState: AppState

    private let ringSize: CGFloat = 260
    private let ringWidth: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: ICareSpacing.lg)

            ZStack {
                ProgressRing(
                    progress: 0,
                    size: ringSize,
                    trackWidth: ringWidth,
                    fillWidth: ringWidth,
                    trackColor: ICareColors.separator,
                    fillColor: ICareColors.statusBlocked
                )
                .opacity(0.3)

                VStack(spacing: ICareSpacing.sm) {
                    Text("NOTIFICATIONS OFF")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ICareColors.statusBlocked)
                        .tracking(1.5)

                    Image(systemName: "bell.slash")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(ICareColors.statusBlocked.opacity(0.6))

                    Text("Enable notifications to\nreceive break reminders")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(ICareColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer(minLength: ICareSpacing.xl)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: ICareSpacing.sm) {
                    Image(systemName: "gear")
                        .font(.system(size: 14))
                    Text("Open Settings")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(ICareColors.brand)
                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ICareSpacing.lg)
            .padding(.bottom, ICareSpacing.base)
        }
    }
}

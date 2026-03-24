import SwiftUI

struct WatchNotificationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showCountdown = false

    var body: some View {
        NavigationStack {
            VStack(spacing: ICareSpacing.sm) {
                Text("Time for a break")
                    .font(ICareTypography.headline)
                    .foregroundStyle(ICareColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Look away for 20 seconds")
                    .font(ICareTypography.body)
                    .foregroundStyle(ICareColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)

                Button {
                    appState.startBreak()
                    showCountdown = true
                } label: {
                    Text("Start")
                        .font(ICareTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ICareSpacing.md)
                        .background(ICareColors.brand)
                        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
                }
                .buttonStyle(.plain)

                SecondaryButton(title: "Snooze") {
                    appState.snooze()
                    dismiss()
                }
            }
            .padding(.horizontal, ICareSpacing.md)
            .padding(.vertical, ICareSpacing.sm)
            .background(ICareColors.surface)
            .navigationDestination(isPresented: $showCountdown) {
                WatchCountdownView()
                    .environmentObject(appState)
            }
        }
    }
}

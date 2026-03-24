import SwiftUI

struct HomePausedContent: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: ICareSpacing.xl) {
            StatusBadge(status: .paused)

            Text("Reminders paused")
                .font(ICareTypography.title)
                .foregroundStyle(ICareColors.statusPaused)
                .multilineTextAlignment(.center)

            Text("Resume when you're ready.")
                .font(ICareTypography.body)
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Resume Reminders") {
                appState.resume()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ICareSpacing.base)
    }
}

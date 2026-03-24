import SwiftUI

struct OnboardingHeader: View {
    let step: Int
    let totalSteps: Int = 3

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                Text("i care")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(ICareColors.brand)

            Spacer()

            Text("STEP \(step) OF \(totalSteps)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ICareColors.textTertiary)
                .tracking(1.5)
        }
    }
}

var onboardingBackground: some View {
    ZStack(alignment: .top) {
        ICareColors.surface.ignoresSafeArea()

        LinearGradient(
            colors: [
                ICareColors.brandMuted,
                ICareColors.surface,
            ],
            startPoint: .top,
            endPoint: .init(x: 0.5, y: 0.35)
        )
        .ignoresSafeArea()
    }
}

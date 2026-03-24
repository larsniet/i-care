import SwiftUI

struct OnboardingHeader: View {
    let step: Int
    let totalSteps: Int = 3

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                Text("icare")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ICareColors.brand)
            }

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

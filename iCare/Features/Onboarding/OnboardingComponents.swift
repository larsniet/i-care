import SwiftUI

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

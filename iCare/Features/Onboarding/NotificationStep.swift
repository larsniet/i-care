import SwiftUI

struct NotificationStep: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Stay on track")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ICareColors.textPrimary)
                    .padding(.bottom, ICareSpacing.sm)

                Text("Quiet notifications nudge you when it's time for a break. You can change this anytime.")
                    .font(ICareTypography.body)
                    .foregroundStyle(ICareColors.textSecondary)
                    .padding(.bottom, ICareSpacing.xxl)

                VStack(spacing: ICareSpacing.sm) {
                    benefitCard(
                        icon: "bell.badge",
                        title: "Gentle reminders",
                        detail: "Short, neutral nudges at the interval you choose"
                    )
                    benefitCard(
                        icon: "applewatch",
                        title: "Haptics on Apple Watch",
                        detail: "A subtle tap on your wrist — no sound needed"
                    )
                    benefitCard(
                        icon: "hand.raised.slash",
                        title: "Never annoying",
                        detail: "No guilt, no streaks, no noise — skip anytime"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ICareSpacing.lg)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func benefitCard(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: ICareSpacing.base) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(ICareColors.brand)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ICareColors.textPrimary)
                Text(detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ICareColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(ICareSpacing.base)
        .background(ICareColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
    }
}

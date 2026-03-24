import SwiftUI

struct WelcomeStep: View {
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Take care\nof your eyes")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ICareColors.textPrimary)
                    .padding(.bottom, ICareSpacing.sm)

                Text("The 20-20-20 rule gives your eyes regular breaks from close-up screen focus.")
                    .font(ICareTypography.body)
                    .foregroundStyle(ICareColors.textSecondary)
                    .padding(.bottom, ICareSpacing.xl)

                heroVisual
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, ICareSpacing.xl)

                ruleVisual
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ICareSpacing.lg)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { appeared = true } }
    }

    // MARK: - Hero

    private var heroVisual: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        ICareColors.brand.opacity(appeared ? [0.08, 0.05, 0.03][i] : 0),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: [140, 190, 240][i],
                        height: [140, 190, 240][i]
                    )
                    .scaleEffect(appeared ? 1 : 0.8)
            }

            Circle()
                .fill(ICareColors.brandMuted)
                .frame(width: 88, height: 88)

            Image(systemName: "eye")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(ICareColors.brand)
                .symbolEffect(.pulse.byLayer, options: .repeating, value: appeared)
        }
        .frame(height: 240)
    }

    // MARK: - Rule Cards

    private var ruleVisual: some View {
        HStack(spacing: ICareSpacing.md) {
            ruleCard(value: "20", unit: "mins", label: "Every", icon: "timer")
            ruleCard(value: "20", unit: "ft", label: "Look", icon: "eye.trianglebadge.exclamationmark")
            ruleCard(value: "20", unit: "sec", label: "For", icon: "hourglass")
        }
    }

    private func ruleCard(value: String, unit: String, label: String, icon: String) -> some View {
        VStack(spacing: ICareSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(ICareColors.brand.opacity(0.5))

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(ICareColors.textTertiary)
                .tracking(1)
                .textCase(.uppercase)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(ICareColors.brand)
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ICareColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ICareSpacing.base)
        .background(ICareColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
    }
}

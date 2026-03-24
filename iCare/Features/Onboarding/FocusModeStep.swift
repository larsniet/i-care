import SwiftUI

struct FocusModeStep: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Works with\nFocus modes")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ICareColors.textPrimary)
                    .padding(.bottom, ICareSpacing.sm)

                Text("Link icare to Work, Study, or any Focus mode so reminders activate automatically.")
                    .font(ICareTypography.body)
                    .foregroundStyle(ICareColors.textSecondary)
                    .padding(.bottom, ICareSpacing.xxl)

                VStack(spacing: ICareSpacing.sm) {
                    instructionCard(
                        step: "1",
                        title: "Open Focus settings",
                        detail: "Settings → Focus → choose a mode"
                    )
                    instructionCard(
                        step: "2",
                        title: "Add a Focus Filter",
                        detail: "Scroll down and tap \"Add Filter\", then select icare"
                    )
                    instructionCard(
                        step: "3",
                        title: "Configure reminders",
                        detail: "Choose whether to enable reminders and set a custom interval"
                    )
                }
                .padding(.bottom, ICareSpacing.lg)

                openSettingsCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ICareSpacing.lg)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func instructionCard(step: String, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: ICareSpacing.base) {
            Text(step)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(ICareColors.brand)
                .clipShape(Circle())

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

    private var openSettingsCard: some View {
        Button {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: ICareSpacing.sm) {
                Image(systemName: "gear")
                    .font(.system(size: 18))
                    .foregroundStyle(ICareColors.brand)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Open Settings")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ICareColors.textPrimary)
                    Text("You can set this up now or anytime later")
                        .font(.system(size: 13))
                        .foregroundStyle(ICareColors.textTertiary)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ICareColors.textTertiary)
            }
            .padding(ICareSpacing.base)
            .background(ICareColors.brand.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md)
                    .stroke(ICareColors.brand.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

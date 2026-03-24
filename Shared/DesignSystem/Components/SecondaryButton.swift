import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ICareTypography.headline)
                .foregroundStyle(ICareColors.brand)
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, ICareSpacing.base)
            .padding(.vertical, ICareSpacing.md)
            .background(configuration.isPressed ? ICareColors.brandMuted : .clear)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            .animation(ICareAnimation.standard, value: configuration.isPressed)
    }
}

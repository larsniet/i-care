import SwiftUI

enum ICareTypography {
    static let displayLarge = Font.system(size: 48, weight: .light, design: .rounded)
    static let displaySmall = Font.system(size: 34, weight: .regular)
    #if os(iOS)
    // Text styles follow the user's text size; at the default size they match the old points.
    static let title = Font.system(.title3, weight: .semibold)
    static let headline = Font.system(.body, weight: .medium)
    static let body = Font.system(.body)
    static let callout = Font.system(.callout)
    static let subhead = Font.system(.subheadline)
    static let caption = Font.system(.caption)
    static let captionMono = Font.system(.caption, design: .monospaced)
    #else
    static let title = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .medium)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subhead = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionMono = Font.system(size: 12, weight: .regular, design: .monospaced)
    #endif
}

/// A fixed-size system font that still grows with Dynamic Type.
private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design))
    }

    /// Keeps content at a comfortable reading width on iPad.
    func readableWidth(_ maxWidth: CGFloat = 560) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}

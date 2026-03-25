import SwiftUI

enum ICareTypography {
    static let displayLarge = Font.system(size: 48, weight: .light, design: .rounded)
    static let displaySmall = Font.system(size: 34, weight: .regular)
    static let title = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .medium)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subhead = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionMono = Font.system(size: 12, weight: .regular, design: .monospaced)
}

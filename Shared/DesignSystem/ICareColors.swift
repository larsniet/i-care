#if os(iOS)
import UIKit
#endif
import SwiftUI

enum ICareColors {
    #if os(iOS)
    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255, alpha: 1)
        })
    }
    #else
    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(red: dark.0 / 255, green: dark.1 / 255, blue: dark.2 / 255)
    }
    #endif

    static let brand = adaptive(light: (8, 107, 89), dark: (123, 205, 184))
    static let brandSubtle = adaptive(light: (160, 242, 219), dark: (26, 61, 51))
    static let brandMuted = adaptive(light: (232, 247, 243), dark: (15, 38, 32))
    static let surface = adaptive(light: (246, 246, 244), dark: (28, 28, 30))
    static let surfaceRaised = adaptive(light: (255, 255, 255), dark: (44, 44, 46))

    static let surfaceOverlay = adaptive(light: (250, 250, 249), dark: (36, 36, 38))

    static let textPrimary = adaptive(light: (26, 29, 30), dark: (240, 240, 238))
    static let textSecondary = adaptive(light: (107, 114, 116), dark: (152, 152, 159))
    static let textTertiary = adaptive(light: (160, 164, 166), dark: (99, 99, 102))
    static let statusPaused = Color(red: 212 / 255, green: 160 / 255, blue: 83 / 255)
    static let statusBlocked = adaptive(light: (196, 92, 86), dark: (232, 134, 127))
    static let separator = adaptive(light: (232, 232, 230), dark: (56, 56, 58))
}

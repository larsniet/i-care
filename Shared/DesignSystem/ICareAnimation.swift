import SwiftUI

enum ICareAnimation {
    static let standard = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let countdown = Animation.linear(duration: 1.0)
    static let stateChange = Animation.easeInOut(duration: 0.3)
}

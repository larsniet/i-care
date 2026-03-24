import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 200
    var trackWidth: CGFloat = 2
    var fillWidth: CGFloat = 3
    var trackColor: Color = ICareColors.brandMuted
    var fillColor: Color = ICareColors.brand

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: trackWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(fillColor, style: StrokeStyle(lineWidth: fillWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

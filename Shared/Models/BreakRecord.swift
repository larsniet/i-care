import Foundation

enum DeviceType: String, Codable, Sendable {
    case iphone
    case watch

    static var current: DeviceType {
        #if os(watchOS)
        return .watch
        #else
        return .iphone
        #endif
    }
}

enum BreakCompletionType: String, Codable, Sendable {
    case completed
    case skipped
    case cancelled
}

struct BreakRecord: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let startedAt: Date
    let completedAt: Date
    let sourceDevice: DeviceType
    let completionType: BreakCompletionType

    init(
        id: String,
        startedAt: Date = Date(),
        completedAt: Date = Date(),
        sourceDevice: DeviceType = .iphone,
        completionType: BreakCompletionType = .completed
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.sourceDevice = sourceDevice
        self.completionType = completionType
    }
}

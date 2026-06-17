import Foundation

enum AutoLockInterval: String, CaseIterable, Identifiable {
    case immediately, thirtySeconds, twoMinutes, fiveMinutes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .immediately:   return "Immediately"
        case .thirtySeconds: return "After 30s"
        case .twoMinutes:    return "After 2 min"
        case .fiveMinutes:   return "After 5 min"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .immediately:   return 0
        case .thirtySeconds: return 30
        case .twoMinutes:    return 120
        case .fiveMinutes:   return 300
        }
    }
}

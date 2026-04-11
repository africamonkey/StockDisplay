import SwiftUI

enum AppTheme: String, CaseIterable {
    case light
    case dark
    case system
}

enum FontSize: String, CaseIterable {
    case verySmall = "very_small"
    case small
    case medium
    case large
    case veryLarge = "very_large"
    
    var scaleFactor: CGFloat {
        switch self {
        case .verySmall: return 0.7
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        case .veryLarge: return 1.3
        }
    }
}

enum StockChangeColorMode: String, CaseIterable {
    case redUpGreenDown
    case greenUpRedDown
    
    var colorForChange: Color {
        switch self {
        case .redUpGreenDown:
            return .red
        case .greenUpRedDown:
            return .green
        }
    }
    
    var colorForDecline: Color {
        switch self {
        case .redUpGreenDown:
            return .green
        case .greenUpRedDown:
            return .red
        }
    }
}

enum AlertType: String, Codable, CaseIterable {
    case upper
    case lower
    
    var displayName: String {
        switch self {
        case .upper: return String(localized: "notification.alert.upper")
        case .lower: return String(localized: "notification.alert.lower")
        }
    }
    
    var notificationKeyword: String {
        switch self {
        case .upper: return String(localized: "notification.alert.upper")
        case .lower: return String(localized: "notification.alert.lower")
        }
    }
}
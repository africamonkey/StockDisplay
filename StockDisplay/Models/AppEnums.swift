import SwiftUI

enum AppTheme: String, CaseIterable {
    case light
    case dark
    case system
}

enum FontSize: String, CaseIterable {
    case small
    case medium
    case large
    
    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
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
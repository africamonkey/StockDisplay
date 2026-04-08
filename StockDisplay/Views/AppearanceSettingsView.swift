import SwiftUI

enum AppTheme: String, CaseIterable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

enum FontSize: String, CaseIterable {
    case small
    case medium
    case large
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue
    @AppStorage("selectedFontSize") private var selectedFontSize: String = FontSize.medium.rawValue
    
    var body: some View {
        List {
            Section("Theme") {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    HStack {
                        Text(theme.displayName)
                        Spacer()
                        if selectedTheme == theme.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTheme = theme.rawValue
                    }
                }
            }
            
            Section("Font Size") {
                ForEach(FontSize.allCases, id: \.self) { size in
                    HStack {
                        Text(size.displayName)
                        Spacer()
                        if selectedFontSize == size.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFontSize = size.rawValue
                    }
                }
            }
        }
        .navigationTitle("Appearance")
    }
}

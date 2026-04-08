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

struct AppearanceSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue
    @AppStorage("selectedFontSize") private var selectedFontSize: String = FontSize.medium.rawValue
    
    private func localizedThemeName(for theme: AppTheme) -> String {
        switch theme {
        case .light:
            return String(localized: "appearance.theme.light")
        case .dark:
            return String(localized: "appearance.theme.dark")
        case .system:
            return String(localized: "appearance.theme.system")
        }
    }
    
    private func localizedFontSizeName(for size: FontSize) -> String {
        switch size {
        case .small:
            return String(localized: "appearance.fontSize.small")
        case .medium:
            return String(localized: "appearance.fontSize.medium")
        case .large:
            return String(localized: "appearance.fontSize.large")
        }
    }
    
    var body: some View {
        List {
            Section(String(localized: "appearance.theme")) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    HStack {
                        Text(localizedThemeName(for: theme))
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
            
            Section(String(localized: "appearance.fontSize")) {
                ForEach(FontSize.allCases, id: \.self) { size in
                    HStack {
                        Text(localizedFontSizeName(for: size))
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
        .navigationTitle(String(localized: "appearance.title"))
    }
}

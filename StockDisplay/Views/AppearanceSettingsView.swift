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

struct AppearanceSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue
    
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
        }
        .navigationTitle("Appearance")
    }
}

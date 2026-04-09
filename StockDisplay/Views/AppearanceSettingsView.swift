import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue
    @AppStorage("selectedFontSize") private var selectedFontSize: String = FontSize.medium.rawValue
    @AppStorage("stockChangeColorMode") private var stockChangeColorMode: String = StockChangeColorMode.redUpGreenDown.rawValue
    @AppStorage("stockListTwoColumns") private var stockListTwoColumns: Bool = false
    
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
        case .verySmall:
            return String(localized: "appearance.fontSize.verySmall")
        case .small:
            return String(localized: "appearance.fontSize.small")
        case .medium:
            return String(localized: "appearance.fontSize.medium")
        case .large:
            return String(localized: "appearance.fontSize.large")
        case .veryLarge:
            return String(localized: "appearance.fontSize.veryLarge")
        }
    }
    
    private func localizedColorModeName(for mode: StockChangeColorMode) -> String {
        switch mode {
        case .redUpGreenDown:
            return String(localized: "appearance.colorMode.redUpGreenDown")
        case .greenUpRedDown:
            return String(localized: "appearance.colorMode.greenUpRedDown")
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
            
            Section(String(localized: "appearance.colorMode")) {
                ForEach(StockChangeColorMode.allCases, id: \.self) { mode in
                    HStack {
                        Text(localizedColorModeName(for: mode))
                        Spacer()
                        if stockChangeColorMode == mode.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        stockChangeColorMode = mode.rawValue
                    }
                }
            }
            
            Section(String(localized: "appearance.layout")) {
                Toggle(String(localized: "appearance.twoColumns"), isOn: $stockListTwoColumns)
            }
        }
        .navigationTitle(String(localized: "appearance.title"))
    }
}

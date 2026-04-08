import SwiftUI

enum AppLanguage: String, CaseIterable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
}

struct LanguageSettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = AppLanguage.english.rawValue
    
    private func localizedName(for language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            return String(localized: "language.simplifiedChinese")
        case .english:
            return String(localized: "language.english")
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    HStack {
                        Text(localizedName(for: language))
                        Spacer()
                        if selectedLanguage == language.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLanguage = language.rawValue
                    }
                }
            }
        }
        .navigationTitle(String(localized: "language.title"))
    }
}

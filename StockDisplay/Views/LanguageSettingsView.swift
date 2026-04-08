import SwiftUI

enum AppLanguage: String, CaseIterable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .simplifiedChinese: return "简体中文"
        case .english: return "English"
        }
    }
}

struct LanguageSettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = AppLanguage.english.rawValue
    
    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    HStack {
                        Text(language.displayName)
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
        .navigationTitle("Language")
    }
}

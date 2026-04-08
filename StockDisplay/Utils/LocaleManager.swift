import SwiftUI
import Combine

final class LocaleManager: ObservableObject {
    static let shared = LocaleManager()
    
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }
    
    var appLocale: Locale {
        switch selectedLanguage {
        case "zh-Hans":
            return Locale(identifier: "zh-Hans")
        default:
            return Locale(identifier: "en")
        }
    }
    
    private init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
    }
}

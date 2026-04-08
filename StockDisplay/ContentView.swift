import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var localeManager = LocaleManager.shared
    
    var body: some View {
        DashboardView()
            .environment(\.locale, localeManager.appLocale)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StockConfig.self, inMemory: true)
}

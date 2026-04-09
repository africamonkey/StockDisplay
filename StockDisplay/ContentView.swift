import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var localeManager = LocaleManager.shared
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = false
    
    var body: some View {
        DashboardView()
            .environment(\.locale, localeManager.appLocale)
            .onAppear {
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = keepScreenOn
                #endif
            }
            .onChange(of: keepScreenOn) { _, newValue in
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = newValue
                #endif
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StockConfig.self, inMemory: true)
}

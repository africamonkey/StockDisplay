//
//  StockDisplayApp.swift
//  StockDisplay
//
//  Created by Africamonkey on 2026/4/7.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@main
struct StockDisplayApp: App {
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue
    @AppStorage("selectedFontSize") private var selectedFontSize: String = FontSize.medium.rawValue
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StockConfig.self,
            DataSourceConfig.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private var colorScheme: ColorScheme? {
        guard let theme = AppTheme(rawValue: selectedTheme) else { return nil }
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    private var fontScale: CGFloat {
        guard let size = FontSize(rawValue: selectedFontSize) else { return 1.0 }
        return size.scaleFactor
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
                .environment(\.fontScale, fontScale)
                .onAppear { NotificationService.shared.requestPermission() }
        }
        .modelContainer(sharedModelContainer)
    }
}

//
//  StockDisplayApp.swift
//  StockDisplay
//
//  Created by Africamonkey on 2026/4/7.
//

import SwiftUI
import SwiftData

@main
struct StockDisplayApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StockConfig.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

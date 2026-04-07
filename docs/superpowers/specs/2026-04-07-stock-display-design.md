# Stock Display Dashboard - Design Spec

## 1. Concept & Vision

A minimal iOS dashboard displaying real-time stock prices with user-configurable API sources. Clean, functional, at-a-glance stock tracking with a date/time header and scrollable stock cards. Settings accessible via gear icon in top-right.

## 2. Design Language

- **Aesthetic**: Native iOS (SwiftUI), clean list-based dashboard
- **Color Palette**:
  - Primary: System Blue (#007AFF)
  - Positive change: Green (#34C759)
  - Negative change: Red (#FF3B30)
  - Background: System background (adaptive light/dark)
- **Typography**: System font, date/time prominent
- **Layout**: Vertical scroll, header fixed conceptually at top, settings via navigation

## 3. Architecture

### Stack
- SwiftUI + SwiftData + async/await + URLSession

### Data Model: `StockConfig` (SwiftData)
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| name | String | Display name (e.g., "Apple Inc.") |
| code | String | Ticker symbol (e.g., "AAPL") |
| apiURL | String | Full API endpoint URL |
| priceJSONPath | String | Dot-notation path (e.g., "data.price") |
| changeJSONPath | String | Dot-notation path (e.g., "data.changePercent") |
| refreshInterval | Int | Seconds: 30, 60, 300, or 0 (manual only) |

### Built-in API Templates
| Template | API URL Pattern | Notes |
|----------|-----------------|-------|
| Yahoo Finance | `https://query1.finance.yahoo.com/v8/finance/chart/{symbol}` | price = `chart.result[0].meta.regularMarketPrice`, change = `chart.result[0].meta.regularMarketChangePercent` |
| Custom | User-provided | Full URL + JSON paths |

### Data Flow
1. Dashboard loads all `StockConfig` from SwiftData on appear
2. For each config, spawn async task to fetch API → extract values via JSONPath → update UI
3. Timer based on shortest non-zero interval triggers refresh cycle
4. Manual refresh via pull-to-refresh or button

## 4. Views & Components

### DashboardView
- **Header**: Date (weekday, month day, year) + Time (HH:mm:ss), updates every second
- **Settings Button**: Gear icon, top-right, navigates to SettingsView
- **Stock List**: ScrollView/LazyVStack of StockCardView items
- **Empty State**: "No stocks added. Tap ⚙️ to add stocks."
- **Pull-to-refresh**: Refreshes all stocks

### StockCardView
- **Layout**: Horizontal - left (name + code), right (price + change)
- **Name**: Bold, 16pt
- **Code**: Gray, 14pt
- **Price**: Bold, 20pt
- **Change**: Colored green/red with % suffix
- **Loading State**: Show "Loading..." placeholder
- **Error State**: Show "Error" in red

### SettingsView
- **Navigation Title**: "Settings"
- **Stock List**: Editable list of added stocks (swipe to delete)
- **Add Button**: "+" in toolbar, navigates to AddStockView
- **Per-stock tap**: Navigates to EditStockView

### AddStockView / EditStockView
- **Template Picker**: Picker with "Yahoo Finance" and "Custom"
- **If Yahoo Finance**:
  - Symbol text field
  - Name text field
  - Auto-populated JSON paths (read-only)
- **If Custom**:
  - Name text field
  - Code text field
  - API URL text field
  - Price JSON Path text field
  - Change JSON Path text field
- **Refresh Interval**: Picker (30s / 1min / 5min / Manual)
- **Save Button**: Validates and saves to SwiftData

### API Fetch Logic
```
func fetchStockData(config: StockConfig) async throws -> (price: Double, change: Double)
1. Guard let url = URL(string: config.apiURL) else { throw URLError }
2. let (data, _) = try await URLSession.shared.data(from: url)
3. let json = try JSONSerialization.jsonObject(with: data)
4. price = jsonValue(at: config.priceJSONPath)
5. change = jsonValue(at: config.changeJSONPath)
```

### JSONPath Extraction
Given root JSON object and path like "data.price":
- Split by "." → ["data", "price"]
- Traverse nested dictionaries/arrays
- Support array index like "data[0].price"

## 5. Technical Approach

- **Framework**: SwiftUI (iOS 17+)
- **Persistence**: SwiftData (ModelContainer)
- **Networking**: URLSession + async/await
- **Concurrency**: TaskGroup for parallel fetches, MainActor for UI updates
- **State**: @Query for SwiftData, @State for local UI state

## 6. File Structure
```
StockDisplay/
├── StockDisplayApp.swift      # App entry, ModelContainer setup
├── ContentView.swift          # → DashboardView
├── Views/
│   ├── DashboardView.swift
│   ├── StockCardView.swift
│   ├── SettingsView.swift
│   └── AddEditStockView.swift
├── Models/
│   └── StockConfig.swift      # SwiftData model
├── Services/
│   └── StockAPIService.swift  # Fetch + JSONPath parsing
└── Utils/
    └── JSONPath.swift         # Dot-notation path extraction
```

## 7. Out of Scope
- iCloud sync
- Multiple portfolios
- Stock charts/graphs
- Price alerts
- Widgets

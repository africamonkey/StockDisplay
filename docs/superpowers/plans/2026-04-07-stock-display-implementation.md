# Stock Display Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working iOS SwiftUI dashboard displaying stock prices from user-configurable APIs

**Architecture:** SwiftUI + SwiftData + async/await + URLSession. Dashboard shows date/time header, scrollable stock cards, and settings button. Stocks configured via settings page with Yahoo Finance template or custom API.

**Tech Stack:** SwiftUI (iOS 17+), SwiftData, URLSession, async/await

---

## File Structure

```
StockDisplay/
├── StockDisplayApp.swift              # Modify: Add ModelContainer for StockConfig
├── ContentView.swift                   # Modify: Replace with DashboardView
├── Models/
│   └── StockConfig.swift               # Create: SwiftData model
├── Views/
│   ├── DashboardView.swift             # Create: Main view with date/time + stock list
│   ├── StockCardView.swift             # Create: Individual stock card
│   ├── SettingsView.swift              # Create: Stock list management
│   └── AddEditStockView.swift          # Create: Add/edit stock form
├── Services/
│   └── StockAPIService.swift           # Create: API fetch + JSONPath extraction
└── Utils/
    └── JSONPath.swift                  # Create: Dot-notation JSON extraction
```

---

## Task 1: Create StockConfig SwiftData Model

**Files:**
- Create: `StockDisplay/Models/StockConfig.swift`
- Modify: `StockDisplay/StockDisplayApp.swift:14` (add StockConfig to schema)

- [ ] **Step 1: Create StockConfig.swift**

```swift
import Foundation
import SwiftData

@Model
final class StockConfig {
    var id: UUID
    var name: String
    var code: String
    var apiURL: String
    var priceJSONPath: String
    var changeJSONPath: String
    var refreshInterval: Int

    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        apiURL: String,
        priceJSONPath: String,
        changeJSONPath: String,
        refreshInterval: Int = 60
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.apiURL = apiURL
        self.priceJSONPath = priceJSONPath
        self.changeJSONPath = changeJSONPath
        self.refreshInterval = refreshInterval
    }
}
```

- [ ] **Step 2: Update StockDisplayApp.swift to include StockConfig in schema**

Change line 14 from:
```swift
Item.self,
```
To:
```swift
StockConfig.self,
```

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Models/StockConfig.swift StockDisplay/StockDisplayApp.swift
git commit -m "feat: add StockConfig SwiftData model"
```

---

## Task 2: Create JSONPath Utility

**Files:**
- Create: `StockDisplay/Utils/JSONPath.swift`

- [ ] **Step 1: Write JSONPath extraction**

```swift
import Foundation

enum JSONPathError: Error {
    case invalidPath
    case valueNotFound
    case typeMismatch
}

func extractValue(from json: Any, path: String) throws -> Any {
    var current: Any = json
    let components = path.split(separator: ".").map(String.init)
    
    for component in components {
        if component.contains("[") && component.contains("]") {
            let parts = component.split(separator: "[")
            let key = String(parts[0])
            let indexStr = parts[1].dropLast()
            guard let index = Int(indexStr) else {
                throw JSONPathError.invalidPath
            }
            guard let dict = current as? [String: Any],
                  let arr = dict[key] as? [Any],
                  index < arr.count else {
                throw JSONPathError.valueNotFound
            }
            current = arr[index]
        } else {
            guard let dict = current as? [String: Any],
                  let value = dict[component] else {
                throw JSONPathError.valueNotFound
            }
            current = value
        }
    }
    return current
}

func extractDouble(from json: Any, path: String) throws -> Double {
    let value = try extractValue(from: json, path: path)
    if let doubleValue = value as? Double {
        return doubleValue
    } else if let intValue = value as? Int {
        return Double(intValue)
    } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
        return doubleValue
    }
    throw JSONPathError.typeMismatch
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Utils/JSONPath.swift
git commit -m "feat: add JSONPath utility for dot-notation extraction"
```

---

## Task 3: Create StockAPIService

**Files:**
- Create: `StockDisplay/Services/StockAPIService.swift`

- [ ] **Step 1: Write StockAPIService**

```swift
import Foundation

struct StockData {
    let price: Double
    let change: Double
}

enum StockAPIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
}

actor StockAPIService {
    static let shared = StockAPIService()
    
    private init() {}
    
    func fetchStockData(config: StockConfig) async throws -> StockData {
        guard let url = URL(string: config.apiURL) else {
            throw StockAPIError.invalidURL
        }
        
        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw StockAPIError.invalidResponse
            }
            data = responseData
        } catch let error as StockAPIError {
            throw error
        } catch {
            throw StockAPIError.networkError(error)
        }
        
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw StockAPIError.decodingError(error)
        }
        
        do {
            let price = try extractDouble(from: json, path: config.priceJSONPath)
            let change = try extractDouble(from: json, path: config.changeJSONPath)
            return StockData(price: price, change: change)
        } catch {
            throw StockAPIError.decodingError(error)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Services/StockAPIService.swift
git commit -m "feat: add StockAPIService for fetching stock data"
```

---

## Task 4: Create StockCardView

**Files:**
- Create: `StockDisplay/Views/StockCardView.swift`

- [ ] **Step 1: Write StockCardView**

```swift
import SwiftUI

enum StockLoadState {
    case idle
    case loading
    case loaded(price: Double, change: Double)
    case error(String)
}

struct StockCardView: View {
    let name: String
    let code: String
    let loadState: StockLoadState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(code)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                switch loadState {
                case .idle, .loading:
                    Text("Loading...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                case .loaded(let price, let change):
                    Text(String(format: "$%.2f", price))
                        .font(.headline)
                    Text(String(format: "%+.2f%%", change))
                        .font(.subheadline)
                        .foregroundStyle(change >= 0 ? .green : .red)
                case .error(let message):
                    Text("Error")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Views/StockCardView.swift
git commit -m "feat: add StockCardView component"
```

---

## Task 5: Create DashboardView

**Files:**
- Create: `StockDisplay/Views/DashboardView.swift`
- Modify: `StockDisplay/ContentView.swift` (replace with DashboardView)

- [ ] **Step 1: Write DashboardView**

```swift
import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stocks: [StockConfig]
    
    @State private var currentDate = Date()
    @State private var stockStates: [UUID: StockLoadState] = [:]
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateTimeHeader
                    .padding()
                
                if stocks.isEmpty {
                    emptyState
                } else {
                    stockList
                }
            }
            .navigationTitle("Stock Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            initializeStockStates()
            startTimer()
            refreshAllStocks()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: stocks) { _, newStocks in
            let newIds = Set(newStocks.map { $0.id })
            let existingIds = Set(stockStates.keys)
            if newIds != existingIds {
                initializeStockStates()
            }
        }
    }
    
    private var dateTimeHeader: some View {
        VStack(spacing: 4) {
            Text(currentDate, format: .dateTime.weekday(.wide).month().day().year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(currentDate, format: .dateTime.hour().minute().second())
                .font(.title)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No stocks added")
                .font(.headline)
            Text("Tap ⚙️ to add stocks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var stockList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(stocks) { stock in
                    StockCardView(
                        name: stock.name,
                        code: stock.code,
                        loadState: stockStates[stock.id] ?? .idle
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await refreshAllStocksAsync()
        }
    }
    
    private func initializeStockStates() {
        for stock in stocks {
            if stockStates[stock.id] == nil {
                stockStates[stock.id] = .idle
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentDate = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func refreshAllStocks() {
        Task {
            await refreshAllStocksAsync()
        }
    }
    
    private func refreshAllStocksAsync() async {
        for stock in stocks {
            stockStates[stock.id] = .loading
        }
        
        await withTaskGroup(of: (UUID, StockLoadState).self) { group in
            for stock in stocks {
                group.addTask {
                    do {
                        let data = try await StockAPIService.shared.fetchStockData(config: stock)
                        return (stock.id, .loaded(price: data.price, change: data.change))
                    } catch {
                        return (stock.id, .error(error.localizedDescription))
                    }
                }
            }
            
            for await (id, state) in group {
                stockStates[id] = state
            }
        }
    }
}
```

- [ ] **Step 2: Replace ContentView.swift with NavigationLink wrapper**

Replace `ContentView.swift` content with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StockConfig.self, inMemory: true)
}
```

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Views/DashboardView.swift StockDisplay/ContentView.swift
git commit -m "feat: add DashboardView with date/time header and stock list"
```

---

## Task 6: Create SettingsView

**Files:**
- Create: `StockDisplay/Views/SettingsView.swift`

- [ ] **Step 1: Write SettingsView**

```swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stocks: [StockConfig]
    
    var body: some View {
        List {
            if stocks.isEmpty {
                Text("No stocks configured")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stocks) { stock in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(stock.name)
                                .font(.headline)
                            Text(stock.code)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(stock.refreshInterval == 0 ? "Manual" : "\(stock.refreshInterval)s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Navigate to edit
                    }
                }
                .onDelete(perform: deleteStocks)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddEditStockView(mode: .add)) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func deleteStocks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(stocks[index])
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Views/SettingsView.swift
git commit -m "feat: add SettingsView for stock management"
```

---

## Task 7: Create AddEditStockView

**Files:**
- Create: `StockDisplay/Views/AddEditStockView.swift`

- [ ] **Step 1: Write AddEditStockView**

```swift
import SwiftUI
import SwiftData

enum StockTemplate: String, CaseIterable {
    case yahooFinance = "Yahoo Finance"
    case custom = "Custom"
}

enum AddEditMode {
    case add
    case edit(StockConfig)
}

struct AddEditStockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: AddEditMode
    
    @State private var template: StockTemplate = .yahooFinance
    @State private var name: String = ""
    @State private var code: String = ""
    @State private var apiURL: String = ""
    @State private var priceJSONPath: String = ""
    @State private var changeJSONPath: String = ""
    @State private var refreshInterval: Int = 60
    
    let refreshOptions = [0, 30, 60, 300]
    
    var body: some View {
        Form {
            Section("Template") {
                Picker("API Template", selection: $template) {
                    ForEach(StockTemplate.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            if template == .yahooFinance {
                Section("Stock Info") {
                    TextField("Symbol (e.g., AAPL)", text: $code)
                        .textInputAutocapitalization(.characters)
                    TextField("Display Name", text: $name)
                }
                
                Section("API Configuration") {
                    LabeledContent("API URL") {
                        Text("https://query1.finance.yahoo.com/v8/finance/chart/{symbol}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Price Path") {
                        Text("chart.result[0].meta.regularMarketPrice")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Change Path") {
                        Text("chart.result[0].meta.regularMarketChangePercent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Refresh Interval") {
                    Picker("Refresh", selection: $refreshInterval) {
                        Text("Manual").tag(0)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                    }
                }
            } else {
                Section("Stock Info") {
                    TextField("Display Name", text: $name)
                    TextField("Symbol / Code", text: $code)
                        .textInputAutocapitalization(.characters)
                }
                
                Section("API Configuration") {
                    TextField("API URL", text: $apiURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Price JSON Path (e.g., data.price)", text: $priceJSONPath)
                        .textInputAutocapitalization(.never)
                    TextField("Change JSON Path (e.g., data.changePercent)", text: $changeJSONPath)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Refresh Interval") {
                    Picker("Refresh", selection: $refreshInterval) {
                        Text("Manual").tag(0)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                    }
                }
            }
        }
        .navigationTitle(mode.isAdd ? "Add Stock" : "Edit Stock")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveStock()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            if case .edit(let stock) = mode {
                populateFromStock(stock)
            }
        }
    }
    
    private var isValid: Bool {
        if template == .yahooFinance {
            return !name.isEmpty && !code.isEmpty
        } else {
            return !name.isEmpty && !code.isEmpty && !apiURL.isEmpty && !priceJSONPath.isEmpty && !changeJSONPath.isEmpty
        }
    }
    
    private func populateFromStock(_ stock: StockConfig) {
        name = stock.name
        code = stock.code
        apiURL = stock.apiURL
        priceJSONPath = stock.priceJSONPath
        changeJSONPath = stock.changeJSONPath
        refreshInterval = stock.refreshInterval
        template = stock.apiURL.contains("yahoo.com") ? .yahooFinance : .custom
    }
    
    private func saveStock() {
        let config: StockConfig
        
        if template == .yahooFinance {
            let url = "https://query1.finance.yahoo.com/v8/finance/chart/\(code)"
            config = StockConfig(
                name: name,
                code: code.uppercased(),
                apiURL: url,
                priceJSONPath: "chart.result[0].meta.regularMarketPrice",
                changeJSONPath: "chart.result[0].meta.regularMarketChangePercent",
                refreshInterval: refreshInterval
            )
        } else {
            if case .edit(let existing) = mode {
                existing.name = name
                existing.code = code.uppercased()
                existing.apiURL = apiURL
                existing.priceJSONPath = priceJSONPath
                existing.changeJSONPath = changeJSONPath
                existing.refreshInterval = refreshInterval
                dismiss()
                return
            }
            
            config = StockConfig(
                name: name,
                code: code.uppercased(),
                apiURL: apiURL,
                priceJSONPath: priceJSONPath,
                changeJSONPath: changeJSONPath,
                refreshInterval: refreshInterval
            )
        }
        
        modelContext.insert(config)
        dismiss()
    }
}

extension AddEditMode {
    var isAdd: Bool {
        if case .add = self { return true }
        return false
    }
}
```

- [ ] **Step 2: Update SettingsView to pass stock for edit**

In `SettingsView.swift`, change the onTapGesture:

```swift
NavigationLink(destination: AddEditStockView(mode: .edit(stock))) {
    EmptyView()
}
```

And wrap the HStack content properly:

```swift
NavigationLink(destination: AddEditStockView(mode: .edit(stock))) {
    HStack {
        VStack(alignment: .leading) {
            Text(stock.name)
                .font(.headline)
            Text(stock.code)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        Spacer()
        Text(stock.refreshInterval == 0 ? "Manual" : "\(stock.refreshInterval)s")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

Remove `.contentShape(Rectangle()).onTapGesture`

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Views/AddEditStockView.swift StockDisplay/Views/SettingsView.swift
git commit -m "feat: add AddEditStockView with template support"
```

---

## Task 8: Add Refresh Timer Logic

**Files:**
- Modify: `StockDisplay/Views/DashboardView.swift`

- [ ] **Step 1: Add background refresh logic**

Add this property to DashboardView:
```swift
@State private var refreshTask: Task<Void, Never>?
```

Replace `startTimer()` and add new refresh logic:

```swift
private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        currentDate = Date()
        checkAndRefresh()
    }
}

private func checkAndRefresh() {
    let minInterval = stocks.map { $0.refreshInterval }.min() ?? 0
    guard minInterval > 0 else { return }
}
```

Actually, a cleaner approach - replace startTimer body with:

```swift
private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        self?.currentDate = Date()
        self?.checkRefreshInterval()
    }
    checkRefreshInterval()
}

private func checkRefreshInterval() {
    let now = Date()
    for stock in stocks {
        if stock.refreshInterval > 0 {
            refreshTask?.cancel()
            refreshTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(stock.refreshInterval) * 1_000_000_000)
                if !Task.isCancelled {
                    await refreshAllStocksAsync()
                }
            }
        }
    }
}
```

Wait, that's not right. Each stock has its own interval. Let me fix:

```swift
private func startAutoRefresh() {
    refreshTask?.cancel()
    refreshTask = Task {
        while !Task.isCancelled {
            let now = Date()
            for stock in stocks {
                if stock.refreshInterval > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(stock.refreshInterval) * 1_000_000_000)
                    if !Task.isCancelled {
                        await refreshStock(stock)
                    }
                }
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
```

Simplify - just use a single timer that checks if any stock needs refresh:

```swift
private func startAutoRefresh() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        self?.currentDate = Date()
    }
    
    refreshTask = Task {
        var lastRefresh: [UUID: Date] = [:]
        while !Task.isCancelled {
            let now = Date()
            for stock in self.stocks {
                if stock.refreshInterval > 0 {
                    let last = lastRefresh[stock.id] ?? .distantPast
                    if now.timeIntervalSince(last) >= Double(stock.refreshInterval) {
                        lastRefresh[stock.id] = now
                        await self.refreshStock(stock)
                    }
                }
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
```

Add helper:
```swift
private func refreshStock(_ stock: StockConfig) async {
    do {
        let data = try await StockAPIService.shared.fetchStockData(config: stock)
        stockStates[stock.id] = .loaded(price: data.price, change: data.change)
    } catch {
        stockStates[stock.id] = .error(error.localizedDescription)
    }
}
```

Update `onDisappear`:
```swift
private func stopTimer() {
    timer?.invalidate()
    timer = nil
    refreshTask?.cancel()
}
```

Update `onChange` to restart refresh:
```swift
.onChange(of: stocks) { _, newStocks in
    let newIds = Set(newStocks.map { $0.id })
    let existingIds = Set(stockStates.keys)
    if newIds != existingIds {
        initializeStockStates()
    }
    refreshTask?.cancel()
    startAutoRefresh()
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Views/DashboardView.swift
git commit -m "feat: add auto-refresh timer logic to DashboardView"
```

---

## Task 9: Build and Verify

**Files:** (none - verification only)

- [ ] **Step 1: Build the project**

Run in Xcode or via command line:
```bash
cd /Users/africamonkey/work/StockDisplay && xcodebuild -project StockDisplay.xcodeproj -scheme StockDisplay -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -50
```

Expected: BUILD SUCCEEDED

- [ ] **Step 2: If build fails, fix errors and rebuild**

Common issues:
- Missing imports
- Type mismatches
- Missing files in Xcode project (run `xcodebuild` shows what files it's looking for)

---

## Spec Coverage Check

- [x] Date/time header with updates every second
- [x] Stock cards showing name, code, price, change with color
- [x] Settings button in top-right corner
- [x] Settings page with add/edit/delete stocks
- [x] Yahoo Finance template with auto-filled paths
- [x] Custom API with manual path entry
- [x] Refresh interval selection (30s/1min/5min/manual)
- [x] API fetching with JSONPath extraction
- [x] Loading and error states on stock cards
- [x] SwiftData persistence
- [x] Pull-to-refresh

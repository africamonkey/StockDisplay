# Price Alert Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add price alert functionality - when stock price breaks through upper/lower threshold, send notification and highlight stock card with yellow blinking animation.

**Architecture:** Create PriceAlert SwiftData model associated with StockConfig. DashboardView manages alert detection on refresh and highlight state. StockCardView handles highlight animation. Notification via UNUserNotificationCenter.

**Tech Stack:** SwiftUI, SwiftData, UserNotifications framework

---

## File Structure

| File | Responsibility |
|------|----------------|
| `Models/PriceAlert.swift` | New model for price alerts |
| `Models/AppEnums.swift` | Add AlertType enum |
| `Views/AddEditStockView.swift` | Add alert configuration UI |
| `Views/StockCardView.swift` | Add highlight state and animation |
| `Views/DashboardView.swift` | Alert detection, highlight state management |
| `StockDisplayApp.swift` | Notification permission request |

---

## Task 1: Create PriceAlert Model

**Files:**
- Create: `StockDisplay/Models/PriceAlert.swift`

- [ ] **Step 1: Create PriceAlert model**

```swift
import Foundation
import SwiftData

enum AlertType: String, Codable {
    case upper
    case lower
}

@Model
final class PriceAlert {
    var id: UUID
    var stockId: UUID
    var alertType: AlertType
    var targetPrice: Double
    var isEnabled: Bool
    var hasTriggered: Bool

    init(
        id: UUID = UUID(),
        stockId: UUID,
        alertType: AlertType,
        targetPrice: Double,
        isEnabled: Bool = true,
        hasTriggered: Bool = false
    ) {
        self.id = id
        self.stockId = stockId
        self.alertType = alertType
        self.targetPrice = targetPrice
        self.isEnabled = isEnabled
        self.hasTriggered = hasTriggered
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Models/PriceAlert.swift
git commit -m "feat: add PriceAlert model"
```

---

## Task 2: Add AlertType to AppEnums

**Files:**
- Modify: `StockDisplay/Models/AppEnums.swift` (add AlertType enum at end of file)

- [ ] **Step 1: Add AlertType enum to AppEnums.swift**

Add after `StockChangeColorMode` enum:

```swift
enum AlertType: String, Codable, CaseIterable {
    case upper
    case lower
    
    var displayName: String {
        switch self {
        case .upper: return "向上突破"
        case .lower: return "向下突破"
        }
    }
    
    var notificationKeyword: String {
        switch self {
        case .upper: return "向上突破"
        case .lower: return "向下突破"
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Models/AppEnums.swift
git commit -m "feat: add AlertType enum"
```

---

## Task 3: Add Alert UI to AddEditStockView

**Files:**
- Modify: `StockDisplay/Views/AddEditStockView.swift`

- [ ] **Step 1: Add PriceAlert Query and state variables**

Add after existing `@State` declarations:

```swift
@State private var alerts: [PriceAlert] = []
@State private var showingAddAlert = false
@State private var newAlertType: AlertType = .upper
@State private var newAlertPrice: String = ""
```

Add `PriceAlert` query after `dataSources` query:

```swift
@Query private var allAlerts: [PriceAlert]
```

- [ ] **Step 2: Add local filtered alerts computed property**

Add computed property:

```swift
private var stockAlerts: [PriceAlert] {
    guard case .edit(let stock) = mode else { return [] }
    return allAlerts.filter { $0.stockId == stock.id }
}
```

- [ ] **Step 3: Add Alerts section in Form body**

Add after the refresh interval Section (before closing `}` of Form):

```swift
Section {
    ForEach(stockAlerts) { alert in
        HStack {
            Text(alert.alertType.displayName)
                .frame(width: 80, alignment: .leading)
            Text(String(format: "%.2f", alert.targetPrice))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    .onDelete(perform: deleteAlerts)
    
    Button {
        showingAddAlert = true
    } label: {
        Label("添加提醒", systemImage: "plus.circle")
    }
}
header: {
    Text("提醒")
}
```

- [ ] **Step 4: Add alert deletion method**

Add after `populateFromStock`:

```swift
private func deleteAlerts(at offsets: IndexSet) {
    let alertsToDelete = offsets.map { stockAlerts[$0] }
    for alert in alertsToDelete {
        modelContext.delete(alert)
    }
}
```

- [ ] **Step 5: Add .sheet for adding new alert**

Add `.sheet` modifier after `.sheet(isPresented: $showingDataSourceEditor)`:

```swift
.sheet(isPresented: $showingAddAlert) {
    NavigationStack {
        Form {
            Section("提醒类型") {
                Picker("类型", selection: $newAlertType) {
                    ForEach(AlertType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("目标价格") {
                TextField("输入价格", text: $newAlertPrice)
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle("添加提醒")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    showingAddAlert = false
                    newAlertPrice = ""
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("添加") {
                    addAlert()
                }
                .disabled(Double(newAlertPrice) == nil)
            }
        }
    }
    .presentationDetents([.medium])
}
```

- [ ] **Step 6: Add addAlert method**

Add after `deleteAlerts`:

```swift
private func addAlert() {
    guard case .edit(let stock) = mode,
          let price = Double(newAlertPrice) else { return }
    
    let alert = PriceAlert(
        stockId: stock.id,
        alertType: newAlertType,
        targetPrice: price
    )
    modelContext.insert(alert)
    
    showingAddAlert = false
    newAlertPrice = ""
}
```

- [ ] **Step 7: Update saveStock to handle new stock alerts**

Modify `saveStock()` to delete old alerts and re-insert when editing:

The existing edit mode code doesn't need changes since alerts are managed separately. For new stock creation, alerts cannot be added (only existing stocks can have alerts). The UI only shows alerts section in edit mode via `stockAlerts` computed property.

- [ ] **Step 8: Commit**

```bash
git add StockDisplay/Views/AddEditStockView.swift
git commit -m "feat: add alert configuration UI to AddEditStockView"
```

---

## Task 4: Add Highlight Animation to StockCardView

**Files:**
- Modify: `StockDisplay/Views/StockCardView.swift`

- [ ] **Step 1: Add isHighlighted property**

Add to `StockCardView` struct:

```swift
let isHighlighted: Bool = false
```

- [ ] **Step 2: Add highlight background modifier**

Add to body `HStack`, replace `.background(Color.gray.opacity(0.15))` with:

```swift
.background(
    Group {
        if isHighlighted {
            Color.yellow.opacity(0.3)
                .overlay(
                    Color.yellow.opacity(0.6)
                        .opacity(isHighlighted ? 1 : 0)
                )
        } else {
            Color.gray.opacity(0.15)
        }
    }
)
.clipShape(RoundedRectangle(cornerRadius: 12))
```

- [ ] **Step 3: Add blinking animation modifier**

Add animation after `.clipShape`:

```swift
.animation(
    isHighlighted ?
        Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
        .default,
    value: isHighlighted
)
```

- [ ] **Step 4: Commit**

```bash
git add StockDisplay/Views/StockCardView.swift
git commit -m "feat: add highlight animation to StockCardView"
```

---

## Task 5: Add Alert Detection and Highlight State to DashboardView

**Files:**
- Modify: `StockDisplay/Views/DashboardView.swift`

- [ ] **Step 1: Add highlightedStocks state and Query**

Add `@State` after existing `@State` declarations:

```swift
@State private var highlightedStocks: Set<UUID> = []
```

Add Query after `dataSources` query:

```swift
@Query private var allAlerts: [PriceAlert]
```

- [ ] **Step 2: Create NotificationService helper**

Add at end of file, before closing brace:

```swift
class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    func sendAlertNotification(stockName: String, stockCode: String, alertType: AlertType, currentPrice: Double, targetPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "\(stockName) (\(stockCode))"
        content.body = "[\(alertType.notificationKeyword)] \(stockName) 现价 \(String(format: "%.2f", currentPrice))，已达到您的目标价 \(String(format: "%.2f", targetPrice))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

Import UserNotifications at top of file:

```swift
import UserNotifications
```

- [ ] **Step 3: Add checkAlerts method**

Add after `refreshAllStocksAsync`:

```swift
private func checkAlerts(for stock: StockConfig, currentPrice: Double) {
    let stockAlerts = allAlerts.filter {
        $0.stockId == stock.id && $0.isEnabled && !$0.hasTriggered
    }
    
    for alert in stockAlerts {
        var shouldTrigger = false
        switch alert.alertType {
        case .upper:
            shouldTrigger = currentPrice >= alert.targetPrice
        case .lower:
            shouldTrigger = currentPrice <= alert.targetPrice
        }
        
        if shouldTrigger {
            alert.hasTriggered = true
            highlightedStocks.insert(stock.id)
            NotificationService.shared.sendAlertNotification(
                stockName: stock.name,
                stockCode: stock.code,
                alertType: alert.alertType,
                currentPrice: currentPrice,
                targetPrice: alert.targetPrice
            )
        }
    }
}
```

- [ ] **Step 4: Modify refreshStock to call checkAlerts**

In `refreshStock` method, after setting `stockStates[stock.id] = .loaded(...)`, add:

```swift
if case .loaded(price: let price, change: _) = stockStates[stock.id] {
    checkAlerts(for: stock, currentPrice: price)
}
```

- [ ] **Step 5: Modify refreshAllStocksAsync to call checkAlerts**

In `refreshAllStocksAsync` method, when returning `.loaded`, also check alerts:

Change:
```swift
return (stock.id, .loaded(price: data.price, change: data.change))
```

To:
```swift
let state = (stock.id, .loaded(price: data.price, change: data.change))
if let stockConfig = stocks.first(where: { $0.id == stock.id }) {
    checkAlerts(for: stockConfig, currentPrice: data.price)
}
return state
```

- [ ] **Step 6: Pass isHighlighted to StockCardView**

In both `singleColumnList` and `twoColumnGrid`, add `isHighlighted`:

```swift
StockCardView(
    name: stock.name,
    code: stock.code,
    loadState: stockStates[stock.id] ?? .idle,
    isHighlighted: highlightedStocks.contains(stock.id)
)
```

- [ ] **Step 7: Commit**

```bash
git add StockDisplay/Views/DashboardView.swift
git commit -m "feat: add alert detection and highlight state to DashboardView"
```

---

## Task 6: Request Notification Permission in App

**Files:**
- Modify: `StockDisplay/StockDisplayApp.swift`

- [ ] **Step 1: Request notification permission on app launch**

Add to `.onAppear` of root view or in `init`:

```swift
NotificationService.shared.requestPermission()
```

Simplest approach: Add `.onAppear { NotificationService.shared.requestPermission() }` to ContentView in StockDisplayApp.

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/StockDisplayApp.swift
git commit -m "feat: request notification permission on app launch"
```

---

## Task 7: Verify Implementation

- [ ] **Step 1: Build project**

Run: `xcodebuild -project StockDisplay.xcodeproj -scheme StockDisplay -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -50`

Expected: BUILD SUCCEEDED

- [ ] **Step 2: Verify all files modified correctly**

Check each modified file matches the design spec.

---

## Spec Coverage

| Spec Section | Tasks |
|--------------|-------|
| Data Model | Task 1, 2 |
| AddEditStockView UI | Task 3 |
| StockCardView highlight | Task 4 |
| DashboardView alert detection | Task 5 |
| Notification system | Task 5, 6 |

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-11-price-alert-implementation.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**

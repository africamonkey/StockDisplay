# Premium In-App Purchase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement StoreKit-based in-app purchase for Premium features including faster refresh intervals (1s, 5s) and price alerts.

**Architecture:** StoreKitManager as a singleton Observable class that handles all purchase logic. Premium status persisted via @AppStorage and synced with Transaction.currentEntitlements on launch.

**Tech Stack:** Swift, StoreKit 2, SwiftUI, @AppStorage

---

## Task 1: Create StoreKitManager Service

**Files:**
- Create: `StockDisplay/Services/StoreKitManager.swift`

- [ ] **Step 1: Create StoreKitManager.swift**

```swift
import Foundation
import StoreKit

@Observable
class StoreKitManager {
    var isPremium: Bool {
        get { _isPremium }
        set { _isPremium = newValue }
    }
    
    private var _isPremium: Bool = false
    private var _products: [Product] = []
    
    var products: [Product] {
        get { _products }
        set { _products = newValue }
    }
    
    private let premiumProductID = "com.yourcompany.stockdisplay.premium"
    
    init() {
        Task {
            await loadProducts()
            await updatePremiumStatus()
            await listenForTransactions()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            _products = try await Product.products(for: [premiumProductID])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func purchase() async throws -> Transaction? {
        guard let product = _products.first else {
            throw StoreKitError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePremiumStatus()
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    @MainActor
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    _isPremium = true
                    try? await transaction.finish()
                    break
                }
            }
        }
    }
    
    @MainActor
    private func updatePremiumStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    _isPremium = true
                    return
                }
            }
        }
        _isPremium = false
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    await MainActor.run {
                        _isPremium = true
                    }
                }
                await transaction.finish()
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}
```

- [ ] **Step 2: Add persistence using AppStorage wrapper**

Modify StoreKitManager to persist isPremium state:

```swift
// Add @AppStorage persistence
class StoreKitManager {
    @AppStorage("isPremium") private var appStorageIsPremium: Bool = false
    
    var isPremium: Bool {
        get { _isPremium }
        set { 
            _isPremium = newValue
            appStorageIsPremium = newValue
        }
    }
    
    // In updatePremiumStatus(), also sync to AppStorage:
    @MainActor
    private func updatePremiumStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    _isPremium = true
                    appStorageIsPremium = true
                    return
                }
            }
        }
        _isPremium = false
        appStorageIsPremium = false
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Services/StoreKitManager.swift
git commit -m "feat: add StoreKitManager for premium in-app purchase"
```

---

## Task 2: Add Premium Section to SettingsView

**Files:**
- Modify: `StockDisplay/Views/SettingsView.swift`

- [ ] **Step 1: Add Premium section with restore purchases button**

Add to SettingsView body after the "otherSettings" Section:

```swift
Section(String(localized: "settings.premium")) {
    if storeKitManager.isPremium {
        Text(String(localized: "premium.unlocked"))
            .foregroundStyle(.green)
    } else {
        Button {
            Task {
                await storeKitManager.restorePurchases()
            }
        } label: {
            Label(String(localized: "premium.restore"), systemImage: "arrow.clockwise")
        }
    }
}
```

- [ ] **Step 2: Add StoreKitManager state**

Add to SettingsView:
```swift
@StateObject private var storeKitManager = StoreKitManager()
```

- [ ] **Step 3: Add localization strings to Localizable.xcstrings**

Add new entries:
```json
"settings.premium": {
    "localizations": {
        "en": { "value": "Premium" },
        "zh-Hans": { "value": "高级版" }
    }
},
"premium.unlocked": {
    "localizations": {
        "en": { "value": "Premium Unlocked" },
        "zh-Hans": { "value": "已解锁高级版" }
    }
},
"premium.restore": {
    "localizations": {
        "en": { "value": "Restore Purchases" },
        "zh-Hans": { "value": "恢复购买" }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add StockDisplay/Views/SettingsView.swift StockDisplay/Localizable.xcstrings
git commit -m "feat: add premium section to settings with restore purchases"
```

---

## Task 3: Restrict Refresh Intervals in AddEditStockView

**Files:**
- Modify: `StockDisplay/Views/AddEditStockView.swift`

- [ ] **Step 1: Add StoreKitManager state**

```swift
@StateObject private var storeKitManager = StoreKitManager()
```

- [ ] **Step 2: Modify refresh interval Picker**

Change the Picker to use conditional intervals:

```swift
Section(String(localized: "addEditStock.refreshInterval")) {
    Picker(String(localized: "addEditStock.refresh"), selection: $refreshInterval) {
        if storeKitManager.isPremium {
            Text(String(localized: "addEditStock.1second")).tag(1)
            Text(String(localized: "addEditStock.5seconds")).tag(5)
        }
        Text(String(localized: "addEditStock.10seconds")).tag(10)
        Text(String(localized: "addEditStock.30seconds")).tag(30)
        Text(String(localized: "addEditStock.1minute")).tag(60)
    }
}
```

- [ ] **Step 3: Ensure valid interval when loading stock**

In `populateFromStock`, if loaded interval is premium-only and user is not premium, reset to 10:

```swift
private func populateFromStock(_ stock: StockConfig) {
    name = stock.name
    code = stock.code
    
    // Downgrade premium-only intervals if user is not premium
    if !storeKitManager.isPremium && [1, 5].contains(stock.refreshInterval) {
        refreshInterval = 10
    } else {
        refreshInterval = stock.refreshInterval
    }
    
    if let dataSourceId = stock.dataSourceId {
        selectedDataSource = dataSources.first { $0.id == dataSourceId }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add StockDisplay/Views/AddEditStockView.swift
git commit -m "feat: restrict refresh intervals based on premium status"
```

---

## Task 4: Hide Price Alerts for Non-Premium Users

**Files:**
- Modify: `StockDisplay/Views/AddEditStockView.swift`

- [ ] **Step 1: Wrap alerts section with premium check**

Change:
```swift
if case .edit = mode {
    Section {
        // alerts UI
    } header: {
        Text(String(localized: "addEditStock.alert.sectionHeader"))
    }
}
```

To:
```swift
if case .edit = mode, storeKitManager.isPremium {
    Section {
        ForEach(stockAlerts) { alert in
            // existing alerts UI
        }
        .onDelete(perform: deleteAlerts)
        
        Button {
            showingAddAlert = true
        } label: {
            Label(String(localized: "addEditStock.alert.add"), systemImage: "plus.circle")
        }
    } header: {
        Text(String(localized: "addEditStock.alert.sectionHeader"))
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Views/AddEditStockView.swift
git commit -m "feat: hide price alerts for non-premium users"
```

---

## Task 5: Implement Import Downgrade Logic

**Files:**
- Modify: `StockDisplay/Views/ConfigFileSettingsView.swift`

- [ ] **Step 1: Add StoreKitManager state**

```swift
@StateObject private var storeKitManager = StoreKitManager()
```

- [ ] **Step 2: Modify processImportData to downgrade refresh intervals**

In `processImportData`, change:

```swift
for (index, importedStock) in configData.stocks.enumerated() {
    let mappedDataSourceId = importedStock.dataSourceId.flatMap { dataSourceIdMapping[$0] }
    
    // Downgrade premium-only intervals if user is not premium
    let finalRefreshInterval: Int
    if storeKitManager.isPremium {
        finalRefreshInterval = importedStock.refreshInterval
    } else {
        finalRefreshInterval = [1, 5].contains(importedStock.refreshInterval)
            ? 10
            : importedStock.refreshInterval
    }
    
    let newStock = StockConfig(
        name: importedStock.name,
        code: importedStock.code,
        dataSourceId: mappedDataSourceId,
        refreshInterval: finalRefreshInterval,
        sortOrder: maxStockSortOrder + index + 1
    )
    modelContext.insert(newStock)
}
```

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Views/ConfigFileSettingsView.swift
git commit -m "feat: downgrade premium refresh intervals on config import for non-premium users"
```

---

## Task 6: Add Localized Strings

**Files:**
- Modify: `StockDisplay/Localizable.xcstrings`

- [ ] **Step 1: Add new localization keys**

Ensure these keys exist:
```json
"addEditStock.1second": {
    "localizations": {
        "en": { "value": "1 second" },
        "zh-Hans": { "value": "1秒" }
    }
},
"addEditStock.5seconds": {
    "localizations": {
        "en": { "value": "5 seconds" },
        "zh-Hans": { "value": "5秒" }
    }
},
"addEditStock.10seconds": {
    "localizations": {
        "en": { "value": "10 seconds" },
        "zh-Hans": { "value": "10秒" }
    }
},
"addEditStock.30seconds": {
    "localizations": {
        "en": { "value": "30 seconds" },
        "zh-Hans": { "value": "30秒" }
    }
},
"addEditStock.1minute": {
    "localizations": {
        "en": { "value": "1 minute" },
        "zh-Hans": { "value": "1分钟" }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Localizable.xcstrings
git commit -m "chore: add refresh interval localization strings"
```

---

## Verification

After implementation, verify:
1. **StoreKit Configuration**: In App Store Connect, create the Premium product with ID `com.yourcompany.stockdisplay.premium`
2. **Test in Sandbox**: Use Sandbox accounts to test purchase and restore flows
3. **UI Verification**: 
   - Non-premium: Only 10s/30s/60s intervals visible, no alerts section
   - Premium: All intervals visible including 1s/5s, alerts section visible
4. **Import Verification**: Import config with 1s/5s intervals as non-premium user → intervals become 10s

---

## Spec Coverage Check

- [x] StoreKit integration with purchase flow
- [x] Restore purchases functionality
- [x] 1s/5s intervals locked to premium
- [x] Price alerts hidden for non-premium
- [x] Import downgrade logic (1s/5s → 10s)
- [x] Persistence via AppStorage

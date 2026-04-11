# Premium Feature In-App Purchase Design

## Overview

Implement an in-app purchase system using StoreKit to unlock Premium features including faster refresh intervals and price alerts.

## Features

### Premium Features
- **1-second refresh interval** - unlock for premium users
- **5-second refresh interval** - unlock for premium users
- **Price alerts** - completely hidden for non-premium users

### Free Tier
- Available refresh intervals: 10s, 30s, 60s
- Price alerts: disabled (hidden UI)

### Purchase Flow
- One Premium product with lifetime access
- Restore purchases functionality for users who reinstall app

## Implementation Details

### 1. StoreKit Manager (`StoreKitManager.swift`)

**Location**: `StockDisplay/Services/StoreKitManager.swift`

**Responsibilities**:
- Initialize StoreKit with `Product.storefront`
- Load and observe `Product.products` for the Premium product
- Handle `Transaction.updates` for re-restoring purchases
- Provide `isPremium` as `@Published` property
- Expose `purchase()` and `restorePurchases()` methods

**API Design**:
```swift
@Observable
class StoreKitManager {
    var isPremium: Bool { get }
    var products: [Product] = []
    
    func loadProducts() async
    func purchase() async throws -> Transaction?
    func restorePurchases() async
}
```

**Data Flow**:
1. On app launch, call `loadProducts()` to fetch products
2. Observe `Transaction.updates` via `listenForTransactions()` 
3. On successful purchase, `isPremium` becomes `true` and is persisted to `@AppStorage("isPremium")`
4. On `restorePurchases()`, iterate through `Transaction.currentEntitlements` and update `isPremium` accordingly

**Persistence**:
- Use `@AppStorage("isPremium") private var isPremium: Bool = false` for local storage
- On app launch, sync `isPremium` from `Transaction.currentEntitlements`

### 2. Refresh Interval Restriction

**Location**: `AddEditStockView.swift`

**Changes**:
- Add `@StateObject private var storeKitManager = StoreKitManager()`
- Conditionally show refresh interval options based on `storeKitManager.isPremium`

**Logic**:
```swift
// Free tier intervals
let freeIntervals = [10, 30, 60]
// Premium-only intervals
let premiumIntervals = [1, 5]
// Available intervals
let availableIntervals = storeKitManager.isPremium 
    ? [1, 5, 10, 30, 60] 
    : [10, 30, 60]
```

### 3. Price Alert Restriction

**Location**: `AddEditStockView.swift`

**Changes**:
- Wrap the alerts `Section` with `if storeKitManager.isPremium { ... }`

### 4. Import Configuration Downgrade

**Location**: `ConfigFileSettingsView.swift`

**Changes**:
- Inject `StoreKitManager` via `@StateObject`
- In `processImportData()`, check `storeKitManager.isPremium`
- If not premium and `importedStock.refreshInterval` is 1 or 5, change to 10

**Logic**:
```swift
let finalRefreshInterval: Int
if storeKitManager.isPremium {
    finalRefreshInterval = importedStock.refreshInterval
} else {
    // Downgrade premium-only intervals to free tier minimum
    finalRefreshInterval = [1, 5].contains(importedStock.refreshInterval) 
        ? 10 
        : importedStock.refreshInterval
}
```

### 5. Premium Settings UI (Optional Enhancement)

**Location**: `SettingsView.swift` or new `PremiumSettingsView.swift`

**Features to add**:
- Show "Premium" badge or status
- "Restore Purchases" button
- Link to Premium product description

### 6. Localization

**New Strings** (add to `Localizable.xcstrings`):
- `premium.title` - "Premium"
- `premium.restore` - "Restore Purchases"
- `premium.purchase` - "Purchase Premium"
- `premium.unlocked` - "Premium Unlocked"
- `settings.premium` - "Premium Settings"

## Testing Considerations

1. **Purchase Flow**: Test successful purchase and verify `isPremium` becomes `true`
2. **Restore Flow**: Test restore purchases after clearing app data
3. **Refresh Interval**: Verify free tier cannot select 1s/5s intervals
4. **Price Alerts**: Verify non-premium users cannot see alert UI
5. **Import Downgrade**: Verify importing config with 1s/5s intervals downgrades to 10s for non-premium users

## File Structure

```
StockDisplay/
├── Services/
│   └── StoreKitManager.swift  (new)
├── Views/
│   ├── SettingsView.swift      (modified)
│   └── AddEditStockView.swift  (modified)
└── Views/
    └── ConfigFileSettingsView.swift  (modified)
```

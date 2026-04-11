# Price Alert Design - 2026-04-11

## Overview

Add price alert functionality to StockDisplay app. When stock price breaks through upper or lower threshold, send system notification and highlight the stock card with yellow blinking animation.

## Data Model

### PriceAlert Model

```swift
enum AlertType: String, Codable {
    case upper  // Price breaks upward
    case lower  // Price breaks downward
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
    )
}
```

**Relationship**: One StockConfig has many PriceAlert (one-to-many).

## UI Changes

### AddEditStockView

Add new Section "提醒" (Alerts) after refresh interval section:

- Button "添加提醒" to add new alert
- For each alert:
  - Picker: 向上突破 / 向下突破
  - TextField: target price (numeric input)
  - Delete button
- Alerts are associated with stock via `stockId`

### StockCardView

Add new property:
- `isHighlighted: Bool`

When `isHighlighted == true`:
- Background: `Color.yellow.opacity(0.3)` with blinking animation
- Animation: 0.5s duration, opacity oscillates between 0.3 and 0.6

### DashboardView

Add state:
- `highlightedStocks: Set<UUID>`

When alert triggers:
1. Add stock ID to `highlightedStocks`
2. Send local notification
3. Update `hasTriggered = true` for the alert

## Alert Detection Logic

In `refreshStock()` method:

1. Fetch all untriggered alerts for the stock where `isEnabled == true`
2. For each alert:
   - If `alertType == .upper && currentPrice >= targetPrice` → trigger
   - If `alertType == .lower && currentPrice <= targetPrice` → trigger
3. On trigger:
   - Send notification
   - Add stock ID to `highlightedStocks`
   - Mark alert as `hasTriggered = true`

## Notification System

- Use `UNUserNotificationCenter` to request permission and send notifications
- Notification content (no currency symbol):
  - Title: `"{stockName} ({stockCode})"`
  - Body: `"[向上突破] {stockName} 现价 {currentPrice}，已达到您的目标价 {targetPrice}"` or `"[向下突破] ..."`

## Storage

- `PriceAlert` stored in SwiftData (same container as StockConfig)
- Alert is created/deleted in AddEditStockView
- `hasTriggered` and `isEnabled` updated by DashboardView

## Files to Modify

1. `StockDisplay/Models/PriceAlert.swift` - New file
2. `StockDisplay/Models/AppEnums.swift` - Add AlertType
3. `StockDisplay/Views/AddEditStockView.swift` - Add alert config UI
4. `StockDisplay/Views/StockCardView.swift` - Add highlight state
5. `StockDisplay/Views/DashboardView.swift` - Add alert detection and highlight state
6. `StockDisplay/StockDisplayApp.swift` - Request notification permission

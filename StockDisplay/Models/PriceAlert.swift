import Foundation
import SwiftData

@Model
final class PriceAlert {
    var id: UUID
    var stockId: UUID
    var alertTypeRaw: String
    var targetPrice: Double
    var isEnabled: Bool
    var hasTriggered: Bool

    var alertType: AlertType {
        get { AlertType(rawValue: alertTypeRaw) ?? .upper }
        set { alertTypeRaw = newValue.rawValue }
    }

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
        self.alertTypeRaw = alertType.rawValue
        self.targetPrice = targetPrice
        self.isEnabled = isEnabled
        self.hasTriggered = hasTriggered
    }
}

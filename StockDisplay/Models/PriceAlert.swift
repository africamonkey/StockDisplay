import Foundation
import SwiftData

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

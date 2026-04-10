import Foundation
import SwiftData

@Model
final class StockConfig {
    var id: UUID
    var name: String
    var code: String
    var dataSourceId: UUID?
    var refreshInterval: Int
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        dataSourceId: UUID? = nil,
        refreshInterval: Int = 10,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.dataSourceId = dataSourceId
        self.refreshInterval = refreshInterval
        self.sortOrder = sortOrder
    }
}

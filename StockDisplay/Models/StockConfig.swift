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
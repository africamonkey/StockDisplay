import Foundation
import SwiftData

@Model
final class DataSourceConfig {
    var id: UUID
    var name: String
    var apiURL: String
    var priceJSONPath: String
    var changeJSONPath: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        apiURL: String,
        priceJSONPath: String,
        changeJSONPath: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.apiURL = apiURL
        self.priceJSONPath = priceJSONPath
        self.changeJSONPath = changeJSONPath
        self.sortOrder = sortOrder
    }
}

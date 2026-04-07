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

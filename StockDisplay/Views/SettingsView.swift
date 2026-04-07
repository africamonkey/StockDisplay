import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stocks: [StockConfig]
    
    @State private var showingAddStock = false
    @State private var newStockName = ""
    @State private var newStockCode = ""
    @State private var newStockAPIURL = ""
    @State private var newStockPricePath = ""
    @State private var newStockChangePath = ""
    
    var body: some View {
        List {
            Section("Configured Stocks") {
                if stocks.isEmpty {
                    Text("No stocks configured")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stocks) { stock in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stock.name)
                                .font(.headline)
                            Text(stock.code)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteStocks)
                }
            }
            
            Section("Add Stock") {
                TextField("Stock Name", text: $newStockName)
                TextField("Stock Code (e.g., AAPL)", text: $newStockCode)
                TextField("API URL", text: $newStockAPIURL)
                TextField("Price JSON Path", text: $newStockPricePath)
                TextField("Change JSON Path", text: $newStockChangePath)
                
                Button("Add Stock") {
                    addStock()
                }
                .disabled(newStockName.isEmpty || newStockCode.isEmpty || newStockAPIURL.isEmpty)
            }
        }
        .navigationTitle("Settings")
    }
    
    private func addStock() {
        let stock = StockConfig(
            name: newStockName,
            code: newStockCode,
            apiURL: newStockAPIURL,
            priceJSONPath: newStockPricePath,
            changeJSONPath: newStockChangePath
        )
        modelContext.insert(stock)
        
        newStockName = ""
        newStockCode = ""
        newStockAPIURL = ""
        newStockPricePath = ""
        newStockChangePath = ""
    }
    
    private func deleteStocks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(stocks[index])
        }
    }
}
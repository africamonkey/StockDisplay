import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stocks: [StockConfig]
    
    var body: some View {
        List {
            Section("Stock Settings") {
                if stocks.isEmpty {
                    Text("No stocks configured")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stocks) { stock in
                        NavigationLink(destination: AddEditStockView(mode: .edit(stock))) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stock.name)
                                        .font(.headline)
                                    Text(stock.code)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(stock.refreshInterval == 0 ? "Manual" : "\(stock.refreshInterval)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteStocks)
                }
                
                NavigationLink(destination: AddEditStockView(mode: .add)) {
                    Label("Add Stock", systemImage: "plus")
                }
            }
            
            Section("Other Settings") {
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label("Appearance", systemImage: "paintbrush")
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    private func deleteStocks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(stocks[index])
            }
        }
    }
}

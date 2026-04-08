import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockConfig.sortOrder) private var stocks: [StockConfig]
    
    var body: some View {
        List {
            Section(String(localized: "settings.stockSettings")) {
                if stocks.isEmpty {
                    Text(String(localized: "settings.noStocksConfigured"))
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
                                Text(stock.refreshInterval == 0 ? String(localized: "stockCard.manual") : "\(stock.refreshInterval)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteStocks)
                    .onMove(perform: moveStocks)
                }
                
                NavigationLink(destination: AddEditStockView(mode: .add)) {
                    Label(String(localized: "settings.addStock"), systemImage: "plus")
                }
            }
            
            Section(String(localized: "settings.otherSettings")) {
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
                }
            }
        }
        .navigationTitle(String(localized: "settings.title"))
        .toolbar {
            EditButton()
        }
    }
    
    private func deleteStocks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(stocks[index])
            }
        }
    }
    
    private func moveStocks(from source: IndexSet, to destination: Int) {
        var reorderedStocks = stocks
        reorderedStocks.move(fromOffsets: source, toOffset: destination)
        
        withAnimation {
            for (index, stock) in reorderedStocks.enumerated() {
                stock.sortOrder = index
            }
        }
    }
}

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: \StockConfig.sortOrder) private var stocks: [StockConfig]
    @Binding var navigationPath: NavigationPath
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = false
    
    var body: some View {
        List {
            Section(String(localized: "settings.stockSettings")) {
                if stocks.isEmpty {
                    Text(String(localized: "settings.noStocksConfigured"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stocks) { stock in
                        Button {
                            navigationPath.append(AppNavigationDestination.editStock(stock))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stock.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
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
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteStocks)
                    .onMove(perform: moveStocks)
                }
                
                Button {
                    navigationPath.append(AppNavigationDestination.addStock)
                } label: {
                    Label(String(localized: "settings.addStock"), systemImage: "plus")
                }
            }
            
            Section(String(localized: "settings.otherSettings")) {
                Toggle(String(localized: "settings.keepScreenOn"), systemImage: "display", isOn: $keepScreenOn)
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
                }
            }
        }
        .navigationTitle(String(localized: "settings.title"))
        .toolbar {
            Button {
                withAnimation {
                    editMode?.wrappedValue = editMode?.wrappedValue == .active ? .inactive : .active
                }
            } label: {
                Text(editMode?.wrappedValue == .active ? String(localized: "settings.done") : String(localized: "settings.edit"))
            }
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

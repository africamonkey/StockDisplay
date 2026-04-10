import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: \StockConfig.sortOrder) private var stocks: [StockConfig]
    @Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
    @Binding var navigationPath: NavigationPath
    @State private var showingDataSourceEditor = false
    @State private var editingDataSource: DataSourceConfig?
    @State private var showDonationView = false
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
            
            Section(String(localized: "settings.dataSourceSettings")) {
                if dataSources.isEmpty {
                    Text(String(localized: "settings.noDataSources"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dataSources) { dataSource in
                        Button {
                            editingDataSource = dataSource
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dataSource.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(dataSource.apiURL)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteDataSources)
                }
                
                Button {
                    editingDataSource = nil
                    showingDataSourceEditor = true
                } label: {
                    Label(String(localized: "settings.addDataSource"), systemImage: "plus")
                }
            }
            
            Section(String(localized: "settings.otherSettings")) {
                Toggle(String(localized: "settings.keepScreenOn"), systemImage: "display", isOn: $keepScreenOn)
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
                }
                NavigationLink(destination: ConfigFileSettingsView()) {
                    Label(String(localized: "settings.configFile"), systemImage: "doc.fill")
                }
            }
            
            Section(String(localized: "settings.about")) {
                Link(destination: URL(string: "https://github.com/africamonkey/StockDisplay")!) {
                    Label(String(localized: "settings.github"), systemImage: "link")
                }
                
                Button {
                    showDonationView = true
                } label: {
                    Label(String(localized: "settings.donate"), systemImage: "heart")
                }
                
                NavigationLink(destination: AboutView()) {
                    Label(String(localized: "settings.aboutApp"), systemImage: "info.circle")
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
        .sheet(isPresented: $showingDataSourceEditor) {
            DataSourceEditorView(dataSource: editingDataSource)
        }
        .sheet(isPresented: $showDonationView) {
            DonationView()
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
    
    private func deleteDataSources(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(dataSources[index])
            }
        }
    }
}

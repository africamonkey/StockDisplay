import SwiftUI
import SwiftData

enum AddEditMode {
    case add
    case edit(StockConfig)
}

struct AddEditStockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: AddEditMode
    
    @StateObject private var storeKitManager = StoreKitManager()
    
    @Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
    @Query private var allAlerts: [PriceAlert]
    @State private var selectedDataSource: DataSourceConfig?
    @State private var showingDataSourceEditor = false
    @State private var name: String = ""
    @State private var code: String = ""
    @State private var refreshInterval: Int = 10
    @State private var showingAddAlert = false
    @State private var newAlertType: AlertType = .upper
    @State private var newAlertPrice: String = ""
    
    var body: some View {
        Form {
            Section(String(localized: "addEditStock.dataSource")) {
                Picker(String(localized: "addEditStock.selectDataSource"), selection: $selectedDataSource) {
                    Text(String(localized: "addEditStock.selectDataSourcePlaceholder"))
                        .tag(nil as DataSourceConfig?)
                    ForEach(dataSources) { ds in
                        Text(ds.name).tag(ds as DataSourceConfig?)
                    }
                }
                
                Button {
                    showingDataSourceEditor = true
                } label: {
                    Label(String(localized: "addEditStock.addNewDataSource"), systemImage: "plus.circle")
                }
            }
            
            if let dataSource = selectedDataSource {
                Section(String(localized: "addEditStock.stockInfo")) {
                    LabeledContent(String(localized: "addEditStock.displayName")) {
                        TextField("", text: $name)
                    }
                    LabeledContent(String(localized: "addEditStock.code")) {
                        TextField("", text: $code)
                            .textInputAutocapitalization(.never)
                    }
                }
                
                Section(String(localized: "addEditStock.apiConfig")) {
                    LabeledContent(String(localized: "addEditStock.apiURL")) {
                        Text(dataSource.apiURL.replacingOccurrences(of: "{code}", with: code.isEmpty ? "{code}" : code))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(String(localized: "addEditStock.pricePath")) {
                        Text(dataSource.priceJSONPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(String(localized: "addEditStock.changePath")) {
                        Text(dataSource.changeJSONPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(String(localized: "addEditStock.refreshInterval")) {
                    Picker(String(localized: "addEditStock.refresh"), selection: $refreshInterval) {
                        if storeKitManager.isPremium {
                            Text(String(localized: "addEditStock.1second")).tag(1)
                            Text(String(localized: "addEditStock.5seconds")).tag(5)
                        }
                        Text(String(localized: "addEditStock.10seconds")).tag(10)
                        Text(String(localized: "addEditStock.30seconds")).tag(30)
                        Text(String(localized: "addEditStock.1minute")).tag(60)
                    }
                }
                
                if case .edit = mode, storeKitManager.isPremium {
                    Section {
                        ForEach(stockAlerts) { alert in
                            HStack {
                                Text(alert.alertType.displayName)
                                    .frame(width: 80, alignment: .leading)
                                Text(String(format: "%.2f", alert.targetPrice))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteAlerts)
                        
                        Button {
                            showingAddAlert = true
                        } label: {
                            Label(String(localized: "addEditStock.alert.add"), systemImage: "plus.circle")
                        }
                    } header: {
                        Text(String(localized: "addEditStock.alert.sectionHeader"))
                    }
                }
            }
        }
        .navigationTitle(mode.isAdd ? String(localized: "addEditStock.title.add") : String(localized: "addEditStock.title.edit"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "addEditStock.save")) {
                    saveStock()
                }
                .disabled(!isValid)
            }
        }
        .sheet(isPresented: $showingDataSourceEditor) {
            DataSourceEditorView(dataSource: nil)
        }
        .sheet(isPresented: $showingAddAlert) {
            NavigationStack {
                Form {
                    Section(String(localized: "addEditStock.alert.type")) {
                        Picker(String(localized: "addEditStock.alert.typeLabel"), selection: $newAlertType) {
                            ForEach(AlertType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section(String(localized: "addEditStock.alert.targetPrice")) {
                        TextField(String(localized: "addEditStock.alert.pricePlaceholder"), text: $newAlertPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                .navigationTitle(String(localized: "addEditStock.alert.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "common.cancel")) {
                            showingAddAlert = false
                            newAlertPrice = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "addEditStock.alert.add")) {
                            addAlert()
                        }
                        .disabled(Double(newAlertPrice) == nil)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: dataSources) { _, newValue in
            if selectedDataSource == nil && !newValue.isEmpty {
                selectedDataSource = newValue.first
            }
        }
        .onAppear {
            if case .edit(let stock) = mode {
                populateFromStock(stock)
            }
        }
    }
    
    private var isValid: Bool {
        selectedDataSource != nil && !name.isEmpty && !code.isEmpty
    }
    
    private var stockAlerts: [PriceAlert] {
        guard case .edit(let stock) = mode else { return [] }
        return allAlerts.filter { $0.stockId == stock.id }
    }
    
    private func populateFromStock(_ stock: StockConfig) {
        name = stock.name
        code = stock.code
        
        if !storeKitManager.isPremium && [1, 5].contains(stock.refreshInterval) {
            refreshInterval = 10
        } else {
            refreshInterval = stock.refreshInterval
        }
        
        if let dataSourceId = stock.dataSourceId {
            selectedDataSource = dataSources.first { $0.id == dataSourceId }
        }
    }
    
    private func deleteAlerts(at offsets: IndexSet) {
        let alertsToDelete = offsets.map { stockAlerts[$0] }
        for alert in alertsToDelete {
            modelContext.delete(alert)
        }
    }
    
private func addAlert() {
        guard case .edit(let stock) = mode,
              let price = Double(newAlertPrice) else { return }
        
        let alert = PriceAlert(
            stockId: stock.id,
            alertType: newAlertType,
            targetPrice: price
        )
        modelContext.insert(alert)
        try? modelContext.save()
        
        showingAddAlert = false
        newAlertPrice = ""
    }
    
    private func saveStock() {
        guard let dataSource = selectedDataSource else { return }
        
        if case .edit(let existing) = mode {
            existing.name = name
            existing.code = code
            existing.dataSourceId = dataSource.id
            existing.refreshInterval = refreshInterval
            dismiss()
            return
        }
        
        let newSortOrder: Int = {
            let descriptor = FetchDescriptor<StockConfig>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
            let existingStocks = (try? modelContext.fetch(descriptor)) ?? []
            return (existingStocks.first?.sortOrder ?? -1) + 1
        }()
        
        let config = StockConfig(
            name: name,
            code: code,
            dataSourceId: dataSource.id,
            refreshInterval: refreshInterval,
            sortOrder: newSortOrder
        )
        
        modelContext.insert(config)
        try? modelContext.save()
        dismiss()
    }
}

extension AddEditMode {
    var isAdd: Bool {
        if case .add = self { return true }
        return false
    }
}

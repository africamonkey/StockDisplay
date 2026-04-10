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
    
    @Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
    @State private var selectedDataSource: DataSourceConfig?
    @State private var showingDataSourceEditor = false
    @State private var name: String = ""
    @State private var code: String = ""
    @State private var refreshInterval: Int = 60
    
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
                        Text(String(localized: "addEditStock.10seconds")).tag(10)
                        Text(String(localized: "addEditStock.30seconds")).tag(30)
                        Text(String(localized: "addEditStock.1minute")).tag(60)
                        Text(String(localized: "addEditStock.5minutes")).tag(300)
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
    
    private func populateFromStock(_ stock: StockConfig) {
        name = stock.name
        code = stock.code
        refreshInterval = stock.refreshInterval
        
        selectedDataSource = dataSources.first { ds in
            ds.apiURL == stock.apiURL &&
            ds.priceJSONPath == stock.priceJSONPath &&
            ds.changeJSONPath == stock.changeJSONPath
        }
    }
    
    private func saveStock() {
        guard let dataSource = selectedDataSource else { return }
        
        let url = dataSource.apiURL.replacingOccurrences(of: "{code}", with: code)
        
        if case .edit(let existing) = mode {
            existing.name = name
            existing.code = code
            existing.apiURL = url
            existing.priceJSONPath = dataSource.priceJSONPath
            existing.changeJSONPath = dataSource.changeJSONPath
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
            apiURL: url,
            priceJSONPath: dataSource.priceJSONPath,
            changeJSONPath: dataSource.changeJSONPath,
            refreshInterval: refreshInterval,
            sortOrder: newSortOrder
        )
        
        modelContext.insert(config)
        dismiss()
    }
}

extension AddEditMode {
    var isAdd: Bool {
        if case .add = self { return true }
        return false
    }
}

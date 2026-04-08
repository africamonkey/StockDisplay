import SwiftUI
import SwiftData

enum StockTemplate: String, CaseIterable {
    case tencentFinance
    case custom
}

enum AddEditMode {
    case add
    case edit(StockConfig)
}

struct AddEditStockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: AddEditMode
    
    @State private var template: StockTemplate = .tencentFinance
    @State private var name: String = ""
    @State private var code: String = ""
    @State private var apiURL: String = ""
    @State private var priceJSONPath: String = ""
    @State private var changeJSONPath: String = ""
    @State private var refreshInterval: Int = 60
    
    var body: some View {
        Form {
            Section(String(localized: "addEditStock.template")) {
                Picker(String(localized: "addEditStock.apiTemplate"), selection: $template) {
                    Text(String(localized: "addEditStock.template.tencent")).tag(StockTemplate.tencentFinance)
                    Text(String(localized: "addEditStock.template.custom")).tag(StockTemplate.custom)
                }
                .pickerStyle(.segmented)
            }
            
            if template == .tencentFinance {
                Section(String(localized: "addEditStock.stockInfo")) {
                    LabeledContent(String(localized: "addEditStock.displayName")) {
                        TextField("", text: $name)
                    }
                    LabeledContent(String(localized: "addEditStock.code")) {
                        TextField("", text: $code).autocapitalization(UITextAutocapitalizationType.none)
                        Text(String(localized: "addEditStock.codeExample"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(String(localized: "addEditStock.apiConfig")) {
                    LabeledContent(String(localized: "addEditStock.apiURL")) {
                        Text("https://web.ifzq.gtimg.cn/portable/mobile/qt/data?code={code}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(String(localized: "addEditStock.pricePath")) {
                        Text("data.newpri")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(String(localized: "addEditStock.changePath")) {
                        Text("data.zdf")
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
            } else {
                Section(String(localized: "addEditStock.stockInfo")) {
                    LabeledContent(String(localized: "addEditStock.displayName")) {
                        TextField("", text: $name)
                    }
                    LabeledContent(String(localized: "addEditStock.code")) {
                        TextField("", text: $code)
                    }
                }
                
                Section(String(localized: "addEditStock.apiConfig")) {
                    TextField(String(localized: "addEditStock.apiURL"), text: $apiURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField(String(localized: "addEditStock.priceJsonPathPlaceholder"), text: $priceJSONPath)
                        .textInputAutocapitalization(.never)
                    TextField(String(localized: "addEditStock.changeJsonPathPlaceholder"), text: $changeJSONPath)
                        .textInputAutocapitalization(.never)
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
        .onAppear {
            if case .edit(let stock) = mode {
                populateFromStock(stock)
            }
        }
    }
    
    private var isValid: Bool {
        if template == .tencentFinance {
            return !name.isEmpty && !code.isEmpty
        } else {
            return !name.isEmpty && !code.isEmpty && !apiURL.isEmpty && !priceJSONPath.isEmpty && !changeJSONPath.isEmpty
        }
    }
    
    private func populateFromStock(_ stock: StockConfig) {
        name = stock.name
        code = stock.code
        apiURL = stock.apiURL
        priceJSONPath = stock.priceJSONPath
        changeJSONPath = stock.changeJSONPath
        refreshInterval = stock.refreshInterval
        template = stock.apiURL.contains("web.ifzq.gtimg.cn") ? .tencentFinance : .custom
    }
    
    private func saveStock() {
        let config: StockConfig
        
        if template == .tencentFinance {
            let url = "https://web.ifzq.gtimg.cn/portable/mobile/qt/data?code=\(code)"
            if case .edit(let existing) = mode {
                existing.name = name
                existing.code = code
                existing.apiURL = url
                existing.priceJSONPath = "data.newpri"
                existing.changeJSONPath = "data.zdf"
                existing.refreshInterval = refreshInterval
                dismiss()
                return
            }
            
            config = StockConfig(
                name: name,
                code: code,
                apiURL: url,
                priceJSONPath: "data.newpri",
                changeJSONPath: "data.zdf",
                refreshInterval: refreshInterval
            )
        } else {
            if case .edit(let existing) = mode {
                existing.name = name
                existing.code = code
                existing.apiURL = apiURL
                existing.priceJSONPath = priceJSONPath
                existing.changeJSONPath = changeJSONPath
                existing.refreshInterval = refreshInterval
                dismiss()
                return
            }
            
            config = StockConfig(
                name: name,
                code: code,
                apiURL: apiURL,
                priceJSONPath: priceJSONPath,
                changeJSONPath: changeJSONPath,
                refreshInterval: refreshInterval
            )
        }
        
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

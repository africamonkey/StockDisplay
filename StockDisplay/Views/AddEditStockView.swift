import SwiftUI
import SwiftData

enum StockTemplate: String, CaseIterable {
    case tencentFinance
    case xueqiu
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
                    Text(String(localized: "addEditStock.template.xueqiu")).tag(StockTemplate.xueqiu)
                    Text(String(localized: "addEditStock.template.custom")).tag(StockTemplate.custom)
                }
                .pickerStyle(.segmented)
            }
            
            if template == .tencentFinance {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(String(localized: "addEditStock.tencentHongKongDelay"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(String(localized: "addEditStock.stockInfo")) {
                    LabeledContent(String(localized: "addEditStock.displayName")) {
                        TextField("", text: $name)
                    }
                    LabeledContent(String(localized: "addEditStock.code")) {
                        TextField("", text: $code)
                            .textInputAutocapitalization(.never)
                        Text(String(localized: "addEditStock.tencentCodeExample"))
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
            } else if template == .xueqiu {
                Section(String(localized: "addEditStock.stockInfo")) {
                    LabeledContent(String(localized: "addEditStock.displayName")) {
                        TextField("", text: $name)
                    }
                    LabeledContent(String(localized: "addEditStock.code")) {
                        TextField("", text: $code)
                            .textInputAutocapitalization(.never)
                        Text(String(localized: "addEditStock.xueqiuCodeExample"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(String(localized: "addEditStock.apiConfig")) {
                    LabeledContent(String(localized: "addEditStock.apiURL")) {
                        Text("https://stock.xueqiu.com/v5/stock/realtime/quotec.json?symbol={code}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(String(localized: "addEditStock.pricePath")) {
                        Text("data[0].current")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(String(localized: "addEditStock.changePath")) {
                        Text("data[0].percent")
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
                            .textInputAutocapitalization(.never)
                    }
                }
                
                Section(String(localized: "addEditStock.apiConfig")) {
                    LabeledContent(String(localized: "addEditStock.apiURL")) {
                        TextField(String(localized: "addEditStock.apiURL"), text: $apiURL)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                    LabeledContent(String(localized: "addEditStock.pricePath")) {
                        TextField(String(localized: "addEditStock.priceJsonPathPlaceholder"), text: $priceJSONPath)
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent(String(localized: "addEditStock.changePath")) {
                        TextField(String(localized: "addEditStock.changeJsonPathPlaceholder"), text: $changeJSONPath)
                            .textInputAutocapitalization(.never)
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
        .onAppear {
            if case .edit(let stock) = mode {
                populateFromStock(stock)
            }
        }
    }
    
    private var isValid: Bool {
        if template == .tencentFinance || template == .xueqiu {
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
        if stock.apiURL.contains("web.ifzq.gtimg.cn") {
            template = .tencentFinance
        } else if stock.apiURL.contains("stock.xueqiu.com") {
            template = .xueqiu
        } else {
            template = .custom
        }
    }
    
    private func saveStock() {
        let config: StockConfig
        
        let newSortOrder: Int = {
            let descriptor = FetchDescriptor<StockConfig>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
            let existingStocks = (try? modelContext.fetch(descriptor)) ?? []
            return (existingStocks.first?.sortOrder ?? -1) + 1
        }()
        
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
                refreshInterval: refreshInterval,
                sortOrder: newSortOrder
            )
        } else if template == .xueqiu {
            let url = "https://stock.xueqiu.com/v5/stock/realtime/quotec.json?symbol=\(code)"
            if case .edit(let existing) = mode {
                existing.name = name
                existing.code = code
                existing.apiURL = url
                existing.priceJSONPath = "data[0].current"
                existing.changeJSONPath = "data[0].percent"
                existing.refreshInterval = refreshInterval
                dismiss()
                return
            }
            
            config = StockConfig(
                name: name,
                code: code,
                apiURL: url,
                priceJSONPath: "data[0].current",
                changeJSONPath: "data[0].percent",
                refreshInterval: refreshInterval,
                sortOrder: newSortOrder
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
                refreshInterval: refreshInterval,
                sortOrder: newSortOrder
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

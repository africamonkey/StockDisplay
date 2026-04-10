import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct ConfigFileData: Codable {
    let version: Int
    let stocks: [StockConfigData]
    let dataSources: [DataSourceConfigData]
}

struct StockConfigData: Codable {
    let id: UUID
    let name: String
    let code: String
    let dataSourceId: UUID?
    let refreshInterval: Int
    let sortOrder: Int
}

struct DataSourceConfigData: Codable {
    let id: UUID
    let name: String
    let apiURL: String
    let priceJSONPath: String
    let changeJSONPath: String
    let sortOrder: Int
}

#if canImport(UIKit)
struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

struct DocumentExporter: UIViewControllerRepresentable {
    let content: String
    let filename: String
    let onComplete: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onComplete: (Bool) -> Void
        
        init(onComplete: @escaping (Bool) -> Void) {
            self.onComplete = onComplete
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onComplete(true)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onComplete(false)
        }
    }
}
#endif

struct ConfigFileSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockConfig.sortOrder) private var stocks: [StockConfig]
    @Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
    
    @State private var urlText: String = ""
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingDocumentPicker: Bool = false
    @State private var showingDocumentExporter: Bool = false
    
    var body: some View {
        List {
            Section(String(localized: "configFile.import")) {
                Button {
                    importFromURL()
                } label: {
                    HStack {
                        Text(String(localized: "configFile.importFromURL"))
                        Spacer()
                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isImporting)
                
                TextField(String(localized: "configFile.urlPlaceholder"), text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button {
                    importFromClipboard()
                } label: {
                    Text(String(localized: "configFile.importFromClipboard"))
                }
                
                Button {
                    showingDocumentPicker = true
                } label: {
                    Text(String(localized: "configFile.importFromFile"))
                }
            }
            
            Section(String(localized: "configFile.export")) {
                Button {
                    exportToClipboard()
                } label: {
                    HStack {
                        Text(String(localized: "configFile.exportToClipboard"))
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
                
                Button {
                    showingDocumentExporter = true
                } label: {
                    Text(String(localized: "configFile.exportToFile"))
                }
                .disabled(isExporting)
            }
        }
        .navigationTitle(String(localized: "configFile.title"))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(types: [.json]) { url in
                importFromFile(url: url)
            }
        }
        .sheet(isPresented: $showingDocumentExporter) {
            DocumentExporter(
                content: buildExportJSON(),
                filename: "stock_config.json"
            ) { success in
                if success {
                    showAlert(
                        title: String(localized: "configFile.exportSuccess"),
                        message: ""
                    )
                }
                isExporting = false
            }
        }
        #endif
    }
    
    private func importFromURL() {
        guard let url = URL(string: urlText) else {
            showAlert(
                title: String(localized: "configFile.importError"),
                message: "Invalid URL"
            )
            return
        }
        
        isImporting = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try await processImportData(data)
                await MainActor.run {
                    isImporting = false
                    showAlert(
                        title: String(localized: "configFile.importSuccess"),
                        message: ""
                    )
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    showAlert(
                        title: String(localized: "configFile.importError"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func importFromClipboard() {
        #if canImport(UIKit)
        guard let clipboardString = UIPasteboard.general.string else {
            showAlert(
                title: String(localized: "configFile.importError"),
                message: "Clipboard is empty"
            )
            return
        }
        
        guard let data = clipboardString.data(using: .utf8) else {
            showAlert(
                title: String(localized: "configFile.importError"),
                message: "Cannot read clipboard content"
            )
            return
        }
        
        Task {
            do {
                try await processImportData(data)
                await MainActor.run {
                    showAlert(
                        title: String(localized: "configFile.importSuccess"),
                        message: ""
                    )
                }
            } catch {
                await MainActor.run {
                    showAlert(
                        title: String(localized: "configFile.importError"),
                        message: error.localizedDescription
                    )
                }
            }
        }
        #endif
    }
    
    private func importFromFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showAlert(
                title: String(localized: "configFile.importError"),
                message: "Cannot access file"
            )
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            Task {
                try await processImportData(data)
                await MainActor.run {
                    showAlert(
                        title: String(localized: "configFile.importSuccess"),
                        message: ""
                    )
                }
            }
        } catch {
            showAlert(
                title: String(localized: "configFile.importError"),
                message: error.localizedDescription
            )
        }
    }
    
    private func processImportData(_ data: Data) async throws {
        let configData = try JSONDecoder().decode(ConfigFileData.self, from: data)
        
        var dataSourceIdMapping: [UUID: UUID] = [:]
        let maxDataSourceSortOrder = dataSources.map(\.sortOrder).max() ?? -1
        
        for (index, importedDS) in configData.dataSources.enumerated() {
            let newDataSource = DataSourceConfig(
                name: importedDS.name,
                apiURL: importedDS.apiURL,
                priceJSONPath: importedDS.priceJSONPath,
                changeJSONPath: importedDS.changeJSONPath,
                sortOrder: maxDataSourceSortOrder + index + 1
            )
            dataSourceIdMapping[importedDS.id] = newDataSource.id
            modelContext.insert(newDataSource)
        }
        
        let maxStockSortOrder = stocks.map(\.sortOrder).max() ?? -1
        
        for (index, importedStock) in configData.stocks.enumerated() {
            let mappedDataSourceId = importedStock.dataSourceId.flatMap { dataSourceIdMapping[$0] }
            let newStock = StockConfig(
                name: importedStock.name,
                code: importedStock.code,
                dataSourceId: mappedDataSourceId,
                refreshInterval: importedStock.refreshInterval,
                sortOrder: maxStockSortOrder + index + 1
            )
            modelContext.insert(newStock)
        }
    }
    
    private func exportToClipboard() {
        #if canImport(UIKit)
        isExporting = true
        let jsonString = buildExportJSON()
        
        UIPasteboard.general.string = jsonString
        showAlert(
            title: String(localized: "configFile.exportSuccess"),
            message: ""
        )
        
        isExporting = false
        #endif
    }
    
    private func buildExportJSON() -> String {
        let stockDataArray = stocks.map { stock in
            StockConfigData(
                id: stock.id,
                name: stock.name,
                code: stock.code,
                dataSourceId: stock.dataSourceId,
                refreshInterval: stock.refreshInterval,
                sortOrder: stock.sortOrder
            )
        }
        
        let dataSourceDataArray = dataSources.map { ds in
            DataSourceConfigData(
                id: ds.id,
                name: ds.name,
                apiURL: ds.apiURL,
                priceJSONPath: ds.priceJSONPath,
                changeJSONPath: ds.changeJSONPath,
                sortOrder: ds.sortOrder
            )
        }
        
        let configFileData = ConfigFileData(
            version: 1,
            stocks: stockDataArray,
            dataSources: dataSourceDataArray
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(configFileData),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

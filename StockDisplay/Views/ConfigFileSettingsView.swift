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

enum ImportError: LocalizedError {
    case invalidVersion
    
    var errorDescription: String? {
        switch self {
        case .invalidVersion:
            return "Invalid or missing version in config file"
        }
    }
}

enum ExportError: LocalizedError {
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode configuration data"
        }
    }
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
    @State private var urlImportText: String = ""
    @State private var showingURLImportAlert: Bool = false
    @State private var showingClipboardImportAlert: Bool = false
    @State private var clipboardImportText: String = ""
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingDocumentPicker: Bool = false
    @State private var showingDocumentExporter: Bool = false
    @State private var exportedData: String = ""
    
    var body: some View {
        List {
            Section(String(localized: "configFile.import")) {
                Button {
                    showingURLImportAlert = true
                } label: {
                    HStack {
                        Text("从URL下载")
                        Spacer()
                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isImporting)
                
                Button {
                    showingClipboardImportAlert = true
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
                    do {
                        exportedData = try buildExportJSON()
                        showingDocumentExporter = true
                    } catch {
                        showAlert(
                            title: String(localized: "configFile.exportError"),
                            message: error.localizedDescription
                        )
                    }
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
        .alert("从URL下载", isPresented: $showingURLImportAlert) {
            Button("取消", role: .cancel) {
                urlImportText = ""
            }
            Button("导入") {
                urlText = urlImportText
                urlImportText = ""
                importFromURL()
            }
        } message: {
            TextField("输入URL...", text: $urlImportText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(types: [.json]) { url in
                importFromFile(url: url)
            }
        }
        .sheet(isPresented: $showingDocumentExporter) {
            DocumentExporter(
                content: exportedData,
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
        .sheet(isPresented: $showingClipboardImportAlert) {
            NavigationStack {
                VStack(spacing: 16) {
                    TextEditor(text: $clipboardImportText)
                        .frame(minHeight: 200)
                        .font(.body)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    HStack {
                        Button("取消") {
                            clipboardImportText = ""
                            showingClipboardImportAlert = false
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("导入") {
                            showingClipboardImportAlert = false
                            importFromClipboardText()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(clipboardImportText.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                .navigationTitle("从剪贴板导入")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
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
                try processImportData(data)
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
    
    private func importFromClipboardText() {
        isImporting = true
        
        guard !clipboardImportText.isEmpty else {
            isImporting = false
            showAlert(
                title: String(localized: "configFile.importError"),
                message: "Input is empty"
            )
            clipboardImportText = ""
            return
        }
        
        guard let data = clipboardImportText.data(using: .utf8) else {
            isImporting = false
            showAlert(
                title: String(localized: "configFile.importError"),
                message: "Cannot read input content"
            )
            clipboardImportText = ""
            return
        }
        
        clipboardImportText = ""
        
        Task {
            do {
                try processImportData(data)
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
                do {
                    try processImportData(data)
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
        } catch {
            showAlert(
                title: String(localized: "configFile.importError"),
                message: error.localizedDescription
            )
        }
    }
    
    private func processImportData(_ data: Data) throws {
        let configData = try JSONDecoder().decode(ConfigFileData.self, from: data)
        
        guard configData.version > 0 else {
            throw ImportError.invalidVersion
        }
        
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
        
        do {
            let jsonString = try buildExportJSON()
            UIPasteboard.general.string = jsonString
            showAlert(
                title: String(localized: "configFile.exportSuccess"),
                message: ""
            )
        } catch {
            showAlert(
                title: String(localized: "configFile.exportError"),
                message: error.localizedDescription
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isExporting = false
        }
        #endif
    }
    
    private func buildExportJSON() throws -> String {
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
        
        let data = try encoder.encode(configFileData)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }
        return jsonString
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

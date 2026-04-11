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
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            try? FileManager.default.removeItem(at: tempURL)
            self.onComplete(completed)
        }
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
    @State private var shouldShowExport: Bool = false
    @StateObject private var storeKitManager = StoreKitManager()
    
    var body: some View {
        List {
            Section(String(localized: "configFile.import")) {
                Button {
                    showingURLImportAlert = true
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
                
                Button {
                    showingClipboardImportAlert = true
                } label: {
                    Text(String(localized: "configFile.importFromTextbox"))
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
                        shouldShowExport = true
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
                .onChange(of: shouldShowExport) { _, newValue in
                    if newValue {
                        DispatchQueue.main.async {
                            self.showingDocumentExporter = true
                            self.shouldShowExport = false
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "configFile.title"))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert(String(localized: "configFile.importFromURL"), isPresented: $showingURLImportAlert) {
            TextField(String(localized: "configFile.urlPlaceholder"), text: $urlImportText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(String(localized: "common.cancel"), role: .cancel) {
                urlImportText = ""
            }
            Button(String(localized: "configFile.import")) {
                urlText = urlImportText
                urlImportText = ""
                importFromURL()
            }
        } message: {
            Text(String(localized: "configFile.urlPlaceholder"))
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(types: [.json]) { url in
                importFromFile(url: url)
            }
        }
        .fullScreenCover(isPresented: $showingDocumentExporter) {
            DocumentExporter(
                content: exportedData,
                filename: "stock_config.json"
            ) { success in
                showingDocumentExporter = false
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
                        Button(String(localized: "common.cancel")) {
                            clipboardImportText = ""
                            showingClipboardImportAlert = false
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button(String(localized: "configFile.import")) {
                            showingClipboardImportAlert = false
                            importFromClipboardText()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(clipboardImportText.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                .navigationTitle(String(localized: "configFile.importFromTextbox"))
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
                message: String(localized: "common.invalidURL")
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
                message: String(localized: "common.inputEmpty")
            )
            clipboardImportText = ""
            return
        }
        
        guard let data = clipboardImportText.data(using: .utf8) else {
            isImporting = false
            showAlert(
                title: String(localized: "configFile.importError"),
                message: String(localized: "common.cannotReadInput")
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
                message: String(localized: "common.cannotAccessFile")
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
            
            let finalRefreshInterval: Int
            if storeKitManager.isPremium {
                finalRefreshInterval = importedStock.refreshInterval
            } else {
                finalRefreshInterval = [1, 5].contains(importedStock.refreshInterval)
                    ? 10
                    : importedStock.refreshInterval
            }
            
            let newStock = StockConfig(
                name: importedStock.name,
                code: importedStock.code,
                dataSourceId: mappedDataSourceId,
                refreshInterval: finalRefreshInterval,
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

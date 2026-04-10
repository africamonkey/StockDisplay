import SwiftUI

struct AboutView: View {
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "StockDisplay"
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text(appName)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section(String(localized: "aboutApp.info")) {
                LabeledContent(String(localized: "aboutApp.version")) {
                    Text(appVersion)
                }
                LabeledContent(String(localized: "aboutApp.build")) {
                    Text(buildNumber)
                }
                LabeledContent(String(localized: "aboutApp.developer")) {
                    Text("Africamonkey")
                }
            }
        }
        .navigationTitle(String(localized: "settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        List {
            Section("Theme") {
                Text("Light")
                Text("Dark")
                Text("System")
            }
        }
        .navigationTitle("Appearance")
    }
}

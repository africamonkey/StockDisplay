import SwiftUI

struct FontSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var fontScale: CGFloat {
        get { self[FontSizeKey.self] }
        set { self[FontSizeKey.self] = newValue }
    }
}

extension View {
    func fontScale(_ scale: CGFloat) -> some View {
        environment(\.fontScale, scale)
    }
}

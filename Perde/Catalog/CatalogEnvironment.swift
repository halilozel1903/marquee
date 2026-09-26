import SwiftUI

private struct CatalogClientKey: EnvironmentKey {
    static let defaultValue = CatalogClient()
}

extension EnvironmentValues {
    var catalogClient: CatalogClient {
        get { self[CatalogClientKey.self] }
        set { self[CatalogClientKey.self] = newValue }
    }
}

import FamilyControls
import Foundation
import ManagedSettings

enum ShieldCoordinator {
    private static let store = ManagedSettingsStore(named: .sleepGuard)

    static func apply(_ selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil
            : selection.webDomainTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }

    static func clear() {
        store.clearAllSettings()
    }
}

extension ManagedSettingsStore.Name {
    static let sleepGuard = Self("sleepGuard")
}


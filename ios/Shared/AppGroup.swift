import Foundation

enum AppGroup {
    static let identifier = "group.com.bellaandc.sleepguard"
    static let selectionKey = "familyActivitySelection"
    static let stateKey = "guardState"
    static let lastShieldActionKey = "lastShieldAction"

    static var defaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: identifier) else {
            preconditionFailure("App Group \(identifier) is not configured")
        }
        return defaults
    }
}


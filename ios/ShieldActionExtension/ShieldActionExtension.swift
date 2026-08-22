import ManagedSettings
import Foundation

final class ShieldActionExtension: ShieldActionDelegate {
    private func respond(to action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        var state = GuardStateStore.load()
        let isUnlockRequest = action == .secondaryButtonPressed
        state.recordShieldAction(isUnlockRequest: isUnlockRequest)
        GuardStateStore.save(state)
        AppGroup.defaults.set(Date.now, forKey: AppGroup.lastShieldActionKey)

        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            if state.unlocksRevoked {
                completionHandler(.close)
            } else {
                if #available(iOS 26.0, *) {
                    completionHandler(.openParentalControlsApp)
                } else {
                    completionHandler(.defer)
                }
            }
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        respond(to: action, completionHandler: completionHandler)
    }
}

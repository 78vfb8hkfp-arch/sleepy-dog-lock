import Foundation

struct GuardState: Codable, Equatable {
    var isActive = false
    var startedAt: Date?
    var endsAt: Date?
    var attemptCount = 0
    var unlockRequestCount = 0
    var unlocksRevoked = false

    mutating func start(now: Date = .now, until: Date) {
        isActive = true
        startedAt = now
        endsAt = until
        attemptCount = 0
        unlockRequestCount = 0
        unlocksRevoked = false
    }

    mutating func stop() {
        isActive = false
        endsAt = nil
    }

    mutating func recordShieldAction(isUnlockRequest: Bool) {
        attemptCount += 1
        if isUnlockRequest { unlockRequestCount += 1 }
        if attemptCount >= 3 { unlocksRevoked = true }
    }
}

enum GuardStateStore {
    static func load() -> GuardState {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.stateKey),
              let state = try? JSONDecoder().decode(GuardState.self, from: data) else {
            return GuardState()
        }
        return state
    }

    static func save(_ state: GuardState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.stateKey)
    }
}


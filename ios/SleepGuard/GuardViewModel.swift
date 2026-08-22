import FamilyControls
import Foundation

@MainActor
final class GuardViewModel: ObservableObject {
    @Published var selection = SelectionStore.load()
    @Published var state = GuardStateStore.load()
    @Published var authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    @Published var errorMessage: String?
    @Published var showingPicker = false

    var selectedItemCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func persistSelection() {
        do {
            try SelectionStore.save(selection)
            if state.isActive { ShieldCoordinator.apply(selection) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startGuard() {
        guard authorizationStatus == .approved else {
            errorMessage = "请先允许屏幕使用时间控制。"
            return
        }
        guard selectedItemCount > 0 else {
            errorMessage = "先选择至少一个需要拦截的 App、分类或网站。"
            return
        }

        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "zh_CN")
        let now = Date.now
        let todayAtEight = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)
            ?? now.addingTimeInterval(3_600)
        let end: Date
        if now < todayAtEight {
            end = todayAtEight
        } else {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)
                ?? now.addingTimeInterval(86_400)
            end = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow)
                ?? tomorrow
        }

        state.start(now: now, until: end)
        GuardStateStore.save(state)
        try? SelectionStore.save(selection)
        ShieldCoordinator.apply(selection)
        do {
            try SleepScheduleCoordinator.schedule(from: now, until: end)
        } catch {
            ShieldCoordinator.clear()
            state.stop()
            GuardStateStore.save(state)
            errorMessage = "系统没能安排早晨自动解锁：\(error.localizedDescription)"
        }
    }

    func stopGuard() {
        state.stop()
        GuardStateStore.save(state)
        ShieldCoordinator.clear()
        SleepScheduleCoordinator.cancel()
    }

    func refresh() {
        state = GuardStateStore.load()
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus

        if state.isActive, let endsAt = state.endsAt, endsAt <= .now {
            stopGuard()
        } else if state.isActive {
            ShieldCoordinator.apply(selection)
        }
    }
}

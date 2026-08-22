import DeviceActivity
import Foundation

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .sleepGuard else { return }

        ShieldCoordinator.clear()
        var state = GuardStateStore.load()
        state.stop()
        GuardStateStore.save(state)
    }
}


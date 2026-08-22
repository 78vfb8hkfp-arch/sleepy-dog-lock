import DeviceActivity
import Foundation

extension DeviceActivityName {
    static let sleepGuard = Self("sleepGuard")
}

enum SleepScheduleCoordinator {
    static func schedule(from start: Date = .now, until end: Date) throws {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: end)
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false,
            warningTime: nil
        )
        let center = DeviceActivityCenter()
        center.stopMonitoring([.sleepGuard])
        try center.startMonitoring(.sleepGuard, during: schedule)
    }

    static func cancel() {
        DeviceActivityCenter().stopMonitoring([.sleepGuard])
    }
}


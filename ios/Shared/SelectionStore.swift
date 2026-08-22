import FamilyControls
import Foundation

enum SelectionStore {
    static func load() -> FamilyActivitySelection {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }

    static func save(_ selection: FamilyActivitySelection) throws {
        let data = try JSONEncoder().encode(selection)
        AppGroup.defaults.set(data, forKey: AppGroup.selectionKey)
    }
}


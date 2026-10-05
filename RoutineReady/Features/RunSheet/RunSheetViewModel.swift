import Foundation
import Observation

@MainActor
@Observable
class RunSheetViewModel {
    var stops: [RunSheetStop] = []
    var errorMessage: ErrorMessage?

    private let loadTodaysRunSheet: LoadTodaysRunSheet

    init(loadTodaysRunSheet: LoadTodaysRunSheet) {
        self.loadTodaysRunSheet = loadTodaysRunSheet
    }

    func load() {
        do {
            stops = try loadTodaysRunSheet.execute()
            errorMessage = nil
        } catch {
            errorMessage = ErrorMessage(error)
        }
    }
}

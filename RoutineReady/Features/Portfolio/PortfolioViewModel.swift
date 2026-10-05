import Foundation
import Observation

@MainActor
@Observable
class PortfolioViewModel {
    var properties: [Property] = []
    var searchText = ""
    var errorMessage: ErrorMessage?

    private let searchPortfolio: SearchPortfolio

    init(searchPortfolio: SearchPortfolio) {
        self.searchPortfolio = searchPortfolio
    }

    func load() {
        do {
            properties = try searchPortfolio.execute(searchText: searchText)
            errorMessage = nil
        } catch {
            errorMessage = ErrorMessage(error)
        }
    }
}

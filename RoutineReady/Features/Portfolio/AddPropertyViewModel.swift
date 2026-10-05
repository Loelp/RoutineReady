import Foundation
import Observation

@MainActor
@Observable
class AddPropertyViewModel {
    var address = ""
    var suburb = ""
    var tenantName = ""
    var landlordName = ""
    var tenancyStartDate = Date()
    var errorMessage: ErrorMessage?

    private let addPropertyToPortfolio: AddPropertyToPortfolio

    init(addPropertyToPortfolio: AddPropertyToPortfolio) {
        self.addPropertyToPortfolio = addPropertyToPortfolio
    }

    // returns true if it saved, so the sheet can close
    func save() -> Bool {
        do {
            try addPropertyToPortfolio.execute(address: address, suburb: suburb, tenantName: tenantName,
                                               landlordName: landlordName, tenancyStartDate: tenancyStartDate)
            return true
        } catch {
            errorMessage = ErrorMessage(error)
            return false
        }
    }
}

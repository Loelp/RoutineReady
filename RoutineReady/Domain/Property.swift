import Foundation

/// A rental property in the property manager's portfolio.
struct Property: Identifiable, Equatable, Hashable {
    let id: UUID
    var address: String
    var suburb: String
    var tenantName: String
    var landlordName: String
    var tenancyStartDate: Date
}

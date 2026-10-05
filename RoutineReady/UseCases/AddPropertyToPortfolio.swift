import Foundation

/// Adds a rental property to the portfolio. Address, suburb, tenant and landlord are all required,
/// because notices and landlord reports are addressed using them.
struct AddPropertyToPortfolio {
    let properties: PropertyRepository

    @discardableResult
    func execute(address: String, suburb: String, tenantName: String, landlordName: String, tenancyStartDate: Date) throws -> Property {
        let property = Property(
            id: UUID(),
            address: address.trimmingCharacters(in: .whitespaces),
            suburb: suburb.trimmingCharacters(in: .whitespaces),
            tenantName: tenantName.trimmingCharacters(in: .whitespaces),
            landlordName: landlordName.trimmingCharacters(in: .whitespaces),
            tenancyStartDate: tenancyStartDate
        )
        if property.address.isEmpty { throw PropertyEntryError.missingAddress }
        if property.suburb.isEmpty { throw PropertyEntryError.missingSuburb }
        if property.tenantName.isEmpty { throw PropertyEntryError.missingTenantName }
        if property.landlordName.isEmpty { throw PropertyEntryError.missingLandlordName }
        try properties.add(property)
        return property
    }
}

enum PropertyEntryError: LocalizedError, Equatable {
    case missingAddress
    case missingSuburb
    case missingTenantName
    case missingLandlordName

    var errorDescription: String? {
        switch self {
        case .missingAddress: "Enter the property's street address."
        case .missingSuburb: "Enter the property's suburb."
        case .missingTenantName: "Enter the tenant's name."
        case .missingLandlordName: "Enter the landlord's name."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingAddress, .missingSuburb: "Notices of entry must show the full address."
        case .missingTenantName: "Notices of entry are addressed to the tenant."
        case .missingLandlordName: "Condition reports are sent to the landlord."
        }
    }
}

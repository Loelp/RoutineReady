import Foundation

/// Adds a new property. Every field is needed because notices go to the tenant at that address
/// and reports go to the landlord.
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

        if property.address.isEmpty {
            throw PropertyEntryError.missingAddress
        }
        if property.suburb.isEmpty {
            throw PropertyEntryError.missingSuburb
        }
        if property.tenantName.isEmpty {
            throw PropertyEntryError.missingTenantName
        }
        if property.landlordName.isEmpty {
            throw PropertyEntryError.missingLandlordName
        }

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
        case .missingAddress:
            return "Enter the street address."
        case .missingSuburb:
            return "Enter the suburb."
        case .missingTenantName:
            return "Enter the tenant's name."
        case .missingLandlordName:
            return "Enter the landlord's name."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingAddress, .missingSuburb:
            return "Notices of entry need the full address."
        case .missingTenantName:
            return "Notices of entry are addressed to the tenant."
        case .missingLandlordName:
            return "Condition reports get sent to the landlord."
        }
    }
}

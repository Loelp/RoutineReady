import Foundation

/// Test and SwiftUI preview stand-in for `CoreDataPropertyRepository`.
final class InMemoryPropertyRepository: PropertyRepository {
    private(set) var stored: [Property]

    init(_ properties: [Property] = []) {
        stored = properties
    }

    func allProperties() throws -> [Property] {
        stored.sorted { ($0.suburb, $0.address) < ($1.suburb, $1.address) }
    }

    func properties(matching text: String) throws -> [Property] {
        try allProperties().filter {
            $0.address.localizedStandardContains(text) || $0.suburb.localizedStandardContains(text)
        }
    }

    func property(withID id: UUID) throws -> Property? {
        stored.first { $0.id == id }
    }

    func add(_ property: Property) throws {
        stored.append(property)
    }
}

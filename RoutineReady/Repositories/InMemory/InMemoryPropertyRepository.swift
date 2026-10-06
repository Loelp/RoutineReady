import Foundation

// Fake repository that keeps everything in an array. Used by the unit tests and SwiftUI previews.
class InMemoryPropertyRepository: PropertyRepository {
    var stored: [Property]

    init(_ properties: [Property] = []) {
        stored = properties
    }

    func allProperties() throws -> [Property] {
        // same order as the Core Data version: suburb, then address
        return stored.sorted { first, second in
            if first.suburb != second.suburb {
                return first.suburb < second.suburb
            }
            return first.address < second.address
        }
    }

    func properties(matching text: String) throws -> [Property] {
        return try allProperties().filter { property in
            property.address.localizedStandardContains(text) || property.suburb.localizedStandardContains(text)
        }
    }

    func property(withID id: UUID) throws -> Property? {
        return stored.first { $0.id == id }
    }

    func add(_ property: Property) throws {
        stored.append(property)
    }
}

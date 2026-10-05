import Foundation

/// The property manager's portfolio of rental properties.
protocol PropertyRepository {
    func allProperties() throws -> [Property]
    /// Properties whose address or suburb contains `text` (case- and diacritic-insensitive).
    func properties(matching text: String) throws -> [Property]
    func property(withID id: UUID) throws -> Property?
    func add(_ property: Property) throws
}

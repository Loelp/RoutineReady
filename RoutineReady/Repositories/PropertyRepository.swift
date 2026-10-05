import Foundation

protocol PropertyRepository {
    func allProperties() throws -> [Property]
    // search by address or suburb (ignores case)
    func properties(matching text: String) throws -> [Property]
    func property(withID id: UUID) throws -> Property?
    func add(_ property: Property) throws
}

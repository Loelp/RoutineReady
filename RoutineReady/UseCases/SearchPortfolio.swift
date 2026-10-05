import Foundation

/// The portfolio sorted by suburb, narrowed to properties whose address or suburb matches the search text.
/// Read-only: the only failures are storage errors, so it has no business error enum.
struct SearchPortfolio {
    let properties: PropertyRepository

    func execute(searchText: String) throws -> [Property] {
        let text = searchText.trimmingCharacters(in: .whitespaces)
        return try text.isEmpty ? properties.allProperties() : properties.properties(matching: text)
    }
}

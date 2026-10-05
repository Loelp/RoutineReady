import Foundation

/// The list of properties, filtered by address or suburb when there's search text.
/// Read only, so no error enum.
struct SearchPortfolio {
    let properties: PropertyRepository

    func execute(searchText: String) throws -> [Property] {
        let text = searchText.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            return try properties.allProperties()
        } else {
            return try properties.properties(matching: text)
        }
    }
}

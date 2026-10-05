import Foundation

/// Supplies "now", so tests can decide what today is.
protocol DateProviding {
    var now: Date { get }
}

struct SystemClock: DateProviding {
    var now: Date { Date() }
}

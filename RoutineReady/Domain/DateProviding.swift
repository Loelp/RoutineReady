import Foundation

// Gives the current date and time. The tests use a fake one so "today" is always the same.
protocol DateProviding {
    var now: Date { get }
}

struct SystemClock: DateProviding {
    var now: Date {
        return Date()
    }
}

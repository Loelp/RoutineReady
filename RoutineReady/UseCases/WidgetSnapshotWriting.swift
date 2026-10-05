import Foundation

// Called after every successful save so the widget (and the share extension's list) stay up to date.
// The tests use a spy version of this to check it gets called.
protocol WidgetSnapshotWriting {
    func refreshWidgetSnapshot()
}

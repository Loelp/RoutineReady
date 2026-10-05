import Foundation

/// Refreshes the files the widget and share extension read, then reloads widget timelines.
/// Called after every successful write; tests inject a spy.
protocol WidgetSnapshotWriting {
    func refreshWidgetSnapshot()
}

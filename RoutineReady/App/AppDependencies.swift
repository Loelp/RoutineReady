import Foundation

/// Composition root. Builds the repositories once and gives each screen's view model the use cases it needs.
/// This is the only place that knows Core Data is behind the repository protocols.
@MainActor
class AppDependencies {
    let properties: PropertyRepository
    let inspections: InspectionRepository
    let inbox: SharedPhotoInbox
    let clock: DateProviding
    let widgetSnapshot: WidgetSnapshotWriting
    let photosDirectory: URL

    init(properties: PropertyRepository, inspections: InspectionRepository, inbox: SharedPhotoInbox,
         clock: DateProviding, widgetSnapshot: WidgetSnapshotWriting, photosDirectory: URL) {
        self.properties = properties
        self.inspections = inspections
        self.inbox = inbox
        self.clock = clock
        self.widgetSnapshot = widgetSnapshot
        self.photosDirectory = photosDirectory
    }

    /// The real app: Core Data, the App Group and the system clock.
    static func live() -> AppDependencies {
        let persistence = PersistenceController()
        let properties = CoreDataPropertyRepository(context: persistence.context)
        let inspections = CoreDataInspectionRepository(context: persistence.context)
        let clock = SystemClock()
        let writer = WidgetSnapshotWriter(
            loadTodaysRunSheet: LoadTodaysRunSheet(properties: properties, inspections: inspections, clock: clock),
            inspections: inspections,
            clock: clock
        )
        DemoDataSeeder(properties: properties, inspections: inspections, clock: clock).seedIfEmpty()
        return AppDependencies(
            properties: properties,
            inspections: inspections,
            inbox: SharedInboxReader(inboxDirectory: AppGroup.inboxDirectory),
            clock: clock,
            widgetSnapshot: writer,
            photosDirectory: AppGroup.photosDirectory
        )
    }

    /// SwiftUI previews: in-memory repositories with the demo portfolio.
    static func preview() -> AppDependencies {
        let properties = InMemoryPropertyRepository()
        let inspections = InMemoryInspectionRepository()
        let clock = SystemClock()
        DemoDataSeeder(properties: properties, inspections: inspections, clock: clock).seedIfEmpty()
        return AppDependencies(
            properties: properties,
            inspections: inspections,
            inbox: InMemorySharedPhotoInbox(),
            clock: clock,
            widgetSnapshot: PreviewWidgetSnapshotWriter(),
            photosDirectory: FileManager.default.temporaryDirectory
        )
    }

    /// Files photos waiting from the share extension and refreshes the widget. Run on launch and whenever the app becomes active.
    func appBecameActive() {
        do {
            try importSharedPhotos.execute()
        } catch {
            print("Could not file shared photos: \(error)")
        }
        widgetSnapshot.refreshWidgetSnapshot()
    }

    // MARK: Use cases

    var loadTodaysRunSheet: LoadTodaysRunSheet {
        LoadTodaysRunSheet(properties: properties, inspections: inspections, clock: clock)
    }

    var scheduleRoutineInspection: ScheduleRoutineInspection {
        ScheduleRoutineInspection(properties: properties, inspections: inspections, publicHolidays: GazettedNSWPublicHolidays(),
                                  clock: clock, widgetSnapshot: widgetSnapshot)
    }

    var logMaintenanceItem: LogMaintenanceItem {
        LogMaintenanceItem(inspections: inspections, clock: clock, widgetSnapshot: widgetSnapshot)
    }

    var importSharedPhotos: ImportSharedPhotos {
        ImportSharedPhotos(inbox: inbox, logMaintenanceItem: logMaintenanceItem)
    }

    // MARK: View models

    func makeRunSheetViewModel() -> RunSheetViewModel {
        RunSheetViewModel(loadTodaysRunSheet: loadTodaysRunSheet)
    }

    func makePortfolioViewModel() -> PortfolioViewModel {
        PortfolioViewModel(searchPortfolio: SearchPortfolio(properties: properties))
    }

    func makeAddPropertyViewModel() -> AddPropertyViewModel {
        AddPropertyViewModel(addPropertyToPortfolio: AddPropertyToPortfolio(properties: properties))
    }

    func makePropertyDetailViewModel(propertyID: UUID) -> PropertyDetailViewModel {
        PropertyDetailViewModel(
            propertyID: propertyID,
            loadPropertyDetail: LoadPropertyDetail(properties: properties, inspections: inspections, clock: clock),
            cancelRoutineInspection: CancelRoutineInspection(inspections: inspections, widgetSnapshot: widgetSnapshot)
        )
    }

    func makeScheduleInspectionViewModel(propertyID: UUID) -> ScheduleInspectionViewModel {
        ScheduleInspectionViewModel(propertyID: propertyID, scheduleRoutineInspection: scheduleRoutineInspection, now: clock.now)
    }

    func makeInspectionInProgressViewModel(inspectionID: UUID) -> InspectionInProgressViewModel {
        InspectionInProgressViewModel(
            inspectionID: inspectionID,
            loadInspection: LoadInspectionInProgress(properties: properties, inspections: inspections),
            logMaintenanceItem: logMaintenanceItem,
            storeDefectPhoto: StoreDefectPhoto(photosDirectory: photosDirectory),
            resolveMaintenanceItem: ResolveMaintenanceItem(inspections: inspections, widgetSnapshot: widgetSnapshot),
            completeRoutineInspection: CompleteRoutineInspection(inspections: inspections, clock: clock, widgetSnapshot: widgetSnapshot)
        )
    }

    func makeSharedPhotosInboxViewModel() -> SharedPhotosInboxViewModel {
        SharedPhotosInboxViewModel(
            importSharedPhotos: importSharedPhotos,
            reassignSharedPhoto: ReassignSharedPhoto(inbox: inbox, importSharedPhotos: importSharedPhotos),
            loadTodaysRunSheet: loadTodaysRunSheet
        )
    }
}

/// Previews don't have a widget to refresh.
struct PreviewWidgetSnapshotWriter: WidgetSnapshotWriting {
    func refreshWidgetSnapshot() {}
}

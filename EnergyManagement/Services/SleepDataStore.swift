import Foundation
import SwiftData

@MainActor
final class SleepDataStore {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    convenience init(inMemory: Bool = false) throws {
        let schema = Schema([
            SleepSchedule.self,
            SleepRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        self.init(modelContext: ModelContext(container))
    }

    func activeSchedule() throws -> SleepSchedule? {
        var descriptor = FetchDescriptor<SleepSchedule>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func saveSchedule(_ schedule: SleepSchedule) throws {
        if schedule.modelContext == nil {
            modelContext.insert(schedule)
        }
        try modelContext.save()
    }

    func record(for localDay: Date, calendar inputCalendar: Calendar = .current) throws -> SleepRecord? {
        let dayStart = inputCalendar.startOfDay(for: localDay)
        guard let dayEnd = inputCalendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return nil
        }
        var descriptor = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.localDay >= dayStart && $0.localDay < dayEnd },
            sortBy: [SortDescriptor(\.localDay, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func records() throws -> [SleepRecord] {
        let descriptor = FetchDescriptor<SleepRecord>(
            sortBy: [SortDescriptor(\.localDay, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func saveRecord(_ record: SleepRecord) throws {
        if record.modelContext == nil {
            modelContext.insert(record)
        }
        try modelContext.save()
    }

    func deleteAllDevelopmentData(allowDestructiveReset: Bool) throws {
        guard allowDestructiveReset else {
            throw SleepDataStoreError.destructiveResetRequiresExplicitDevelopmentFlag
        }

        for record in try records() {
            modelContext.delete(record)
        }

        let schedules = try modelContext.fetch(FetchDescriptor<SleepSchedule>())
        for schedule in schedules {
            modelContext.delete(schedule)
        }

        try modelContext.save()
    }
}

enum SleepDataStoreError: Error, Equatable {
    case destructiveResetRequiresExplicitDevelopmentFlag
}

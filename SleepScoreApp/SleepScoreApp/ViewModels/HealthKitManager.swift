import Foundation
import HealthKit
import Combine

extension Array where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var sleepData: [SleepRecord] = []
    @Published var errorMessage: String?
    
    init() {
        requestHealthKitPermission()
    }
    
    func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            print("HealthKit not available")
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let typesToRead: Set<HKObjectType> = [sleepType]
        
        print("Requesting HealthKit authorization...")
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                print("Authorization result: success=\(success), error=\(error?.localizedDescription ?? "none")")
                if success {
                    self?.isAuthorized = true
                    self?.fetchSleepData()
                } else {
                    self?.errorMessage = error?.localizedDescription ?? "Failed to get HealthKit authorization"
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    func fetchSleepData() {
        guard isAuthorized else {
            errorMessage = "HealthKit not authorized"
            return
        }
        
        // Clear previous data to ensure fresh sync
        sleepData = []
        errorMessage = nil
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        
        // Extend the end date to tomorrow to ensure we get last night's sleep
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        // Fetch 60 days of data for better coverage
        let startDate = calendar.date(byAdding: .day, value: -60, to: now) ?? now
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: tomorrow, options: .strictStartDate)
        
        print("Fetching sleep data from \(startDate) to \(tomorrow)")
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit query error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    print("No sleep samples found")
                    self?.errorMessage = "No sleep data found"
                    return
                }
                
                print("Found \(samples.count) sleep samples")
                self?.processSleepSamples(samples)
            }
        }
        
        healthStore.execute(query)
    }
    
    func forceRefreshSleepData() {
        // Force a fresh query by adding a small delay and clearing all caches
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.fetchSleepData()
        }
    }
    
    private func processSleepSamples(_ samples: [HKCategorySample]) {
        print("Processing \(samples.count) sleep samples")
        
        let sleepRecords = samples.compactMap { sample -> SleepRecord? in
            guard let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { 
                print("Invalid sleep value: \(sample.value)")
                return nil 
            }
            
            // Capture all sleep states for debugging
            print("Sleep sample: \(sample.startDate) - \(sample.endDate) (\(sleepValue))")
            
            return SleepRecord(
                startDate: sample.startDate,
                endDate: sample.endDate,
                sleepType: sleepValue,
                source: sample.sourceRevision.source.name
            )
        }
        
        print("Created \(sleepRecords.count) valid sleep records")
        self.sleepData = sleepRecords
        
        // Log summary with detailed date information
        let calendar = Calendar.current
        let groupedByDate = Dictionary(grouping: sleepRecords) { record in
            calendar.startOfDay(for: record.startDate)
        }
        
        print("Sleep data summary:")
        for (date, records) in groupedByDate.sorted(by: { $0.key > $1.key }) {
            let totalHours = records.reduce(0) { total, record in
                total + record.durationHours
            }
            let sleepTypes = records.map { $0.sleepType }.unique()
            print("  \(date): \(records.count) records, \(String(format: "%.1f", totalHours)) hours, types: \(sleepTypes)")
        }
        
        // Check for recent dates
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        print("Recent data check:")
        print("  Today (\(today)): \(groupedByDate[today]?.count ?? 0) records")
        print("  Yesterday (\(yesterday)): \(groupedByDate[yesterday]?.count ?? 0) records")
        print("  Two days ago (\(twoDaysAgo)): \(groupedByDate[twoDaysAgo]?.count ?? 0) records")
    }
}

struct SleepRecord: Equatable {
    let startDate: Date
    let endDate: Date
    let sleepType: HKCategoryValueSleepAnalysis
    let source: String
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var durationHours: Double {
        duration / 3600
    }
    
    static func == (lhs: SleepRecord, rhs: SleepRecord) -> Bool {
        return lhs.startDate == rhs.startDate &&
               lhs.endDate == rhs.endDate &&
               lhs.sleepType == rhs.sleepType &&
               lhs.source == rhs.source
    }
}

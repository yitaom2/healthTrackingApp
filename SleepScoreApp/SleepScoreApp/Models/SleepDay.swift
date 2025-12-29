import Foundation
import SwiftUI

enum SleepRating: String, CaseIterable, Codable {
    case perfect = "Perfect"
    case good = "Good"
    case ok = "OK"
    case not_meet = "Not Meet"
    
    var color: Color {
        switch self {
        case .perfect:
            return Color(red: 0.0, green: 0.8, blue: 0.0) // Brighter green
        case .good:
            return Color(red: 0.7, green: 0.9, blue: 0.7) // Pale green
        case .ok:
            return Color(red: 1.0, green: 1.0, blue: 0.7) // Pale yellow
        case .not_meet:
            return Color(red: 0.8, green: 0.8, blue: 0.8) // Pale gray
        }
    }
}

enum SleepSource: String, CaseIterable, Codable {
    case apple_watch = "Apple Watch"
    case manual = "Manual"
}

struct SleepDay: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let actualStart: Date
    let actualEnd: Date
    let durationHours: Double
    let rating: SleepRating
    let source: SleepSource
    let createdAt: Date
    
    init(date: Date, actualStart: Date, actualEnd: Date, durationHours: Double, rating: SleepRating, source: SleepSource) {
        self.date = date
        self.actualStart = actualStart
        self.actualEnd = actualEnd
        self.durationHours = durationHours
        self.rating = rating
        self.source = source
        self.createdAt = Date()
    }
    
    init(
        date: Date,
        actualStart: Date,
        actualEnd: Date,
        durationHours: Double,
        source: SleepSource,
        sleepGoal: SleepGoal
    ) {
        self.date = date
        self.actualStart = actualStart
        self.actualEnd = actualEnd
        self.durationHours = durationHours
        self.source = source
        self.rating = SleepRatingEngine.calculateRating(
            duration: durationHours,
            goalHours: sleepGoal.targetSleepHours,
            sleepStart: actualStart,
            sleepEnd: actualEnd,
            bedtimeStart: sleepGoal.bedtimeStart,
            bedtimeEnd: sleepGoal.bedtimeEnd,
            wakeWindowStart: sleepGoal.wakeWindowStart,
            wakeWindowEnd: sleepGoal.wakeWindowEnd
        )
        self.createdAt = Date()
    }
}

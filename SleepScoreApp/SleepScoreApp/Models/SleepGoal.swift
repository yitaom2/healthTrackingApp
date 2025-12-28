import Foundation

struct SleepGoal: Codable {
    var bedtimeStart: Date
    var bedtimeEnd: Date
    var wakeWindowStart: Date
    var wakeWindowEnd: Date
    var targetSleepHours: Double
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        
        // Default bedtime: 10:00 PM - 11:00 PM
        bedtimeStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now) ?? now
        bedtimeEnd = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
        
        // Default wake window: 6:00 AM - 8:00 AM
        wakeWindowStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
        wakeWindowEnd = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        
        // Default target: 8 hours
        targetSleepHours = 8.0
    }
}

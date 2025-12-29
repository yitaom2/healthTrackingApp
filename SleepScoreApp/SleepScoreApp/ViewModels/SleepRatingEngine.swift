import Foundation

class SleepRatingEngine {
    
    static func calculateRating(
        duration: Double,
        goalHours: Double,
        sleepStart: Date,
        sleepEnd: Date,
        bedtimeStart: Date,
        bedtimeEnd: Date,
        wakeWindowStart: Date,
        wakeWindowEnd: Date
    ) -> SleepRating {
        
        // Check if duration meets goal and sleep is within windows
        let durationMeetsGoal = duration >= goalHours
        let sleepWithinWindows = isSleepWithinWindows(
            sleepStart: sleepStart,
            sleepEnd: sleepEnd,
            bedtimeStart: bedtimeStart,
            bedtimeEnd: bedtimeEnd,
            wakeWindowStart: wakeWindowStart,
            wakeWindowEnd: wakeWindowEnd
        )
        
        // Apply rating logic
        if durationMeetsGoal && sleepWithinWindows {
            return .perfect
        } else if durationMeetsGoal {
            return .good
        } else if (goalHours - duration) <= 1.0 {
            return .ok
        } else {
            return .not_meet
        }
    }
    
    private static func isSleepWithinWindows(
        sleepStart: Date,
        sleepEnd: Date,
        bedtimeStart: Date,
        bedtimeEnd: Date,
        wakeWindowStart: Date,
        wakeWindowEnd: Date
    ) -> Bool {
        let calendar = Calendar.current
        
        // Add 45-minute buffer to sleep window
        let bufferedBedtimeStart = calendar.date(byAdding: .minute, value: -45, to: bedtimeStart) ?? bedtimeStart
        let bufferedBedtimeEnd = calendar.date(byAdding: .minute, value: 45, to: bedtimeEnd) ?? bedtimeEnd
        let bufferedWakeStart = calendar.date(byAdding: .minute, value: -45, to: wakeWindowStart) ?? wakeWindowStart
        let bufferedWakeEnd = calendar.date(byAdding: .minute, value: 45, to: wakeWindowEnd) ?? wakeWindowEnd
        
        // Normalize all times to the same day for comparison
        let sleepStartComponents = calendar.dateComponents([.hour, .minute], from: sleepStart)
        let sleepEndComponents = calendar.dateComponents([.hour, .minute], from: sleepEnd)
        
        let bufferedBedtimeStartComponents = calendar.dateComponents([.hour, .minute], from: bufferedBedtimeStart)
        let bufferedBedtimeEndComponents = calendar.dateComponents([.hour, .minute], from: bufferedBedtimeEnd)
        
        let bufferedWakeStartComponents = calendar.dateComponents([.hour, .minute], from: bufferedWakeStart)
        let bufferedWakeEndComponents = calendar.dateComponents([.hour, .minute], from: bufferedWakeEnd)
        
        // Create reference date for time comparison
        let referenceDate = calendar.startOfDay(for: sleepStart)
        
        guard let sleepStartTime = calendar.date(byAdding: sleepStartComponents, to: referenceDate),
              let sleepEndTime = calendar.date(byAdding: sleepEndComponents, to: referenceDate),
              let bedtimeStartTime = calendar.date(byAdding: bufferedBedtimeStartComponents, to: referenceDate),
              let bedtimeEndTime = calendar.date(byAdding: bufferedBedtimeEndComponents, to: referenceDate),
              let wakeStartTime = calendar.date(byAdding: bufferedWakeStartComponents, to: referenceDate),
              let wakeEndTime = calendar.date(byAdding: bufferedWakeEndComponents, to: referenceDate) else {
            return false
        }
        
        // Check if sleep start is within buffered bedtime window
        let sleepStartInBedtimeWindow = isTimeInRange(
            time: sleepStartTime,
            rangeStart: bedtimeStartTime,
            rangeEnd: bedtimeEndTime
        )
        
        // Check if sleep end is within buffered wake window
        let sleepEndInWakeWindow = isTimeInRange(
            time: sleepEndTime,
            rangeStart: wakeStartTime,
            rangeEnd: wakeEndTime
        )
        
        return sleepStartInBedtimeWindow && sleepEndInWakeWindow
    }
    
    private static func isTimeInRange(time: Date, rangeStart: Date, rangeEnd: Date) -> Bool {
        // Handle case where range spans midnight (e.g., 22:00 to 06:00)
        if rangeStart > rangeEnd {
            // Range spans midnight, so time is in range if it's >= start OR <= end
            return time >= rangeStart || time <= rangeEnd
        } else {
            // Normal range, time is in range if it's between start and end
            return time >= rangeStart && time <= rangeEnd
        }
    }
}

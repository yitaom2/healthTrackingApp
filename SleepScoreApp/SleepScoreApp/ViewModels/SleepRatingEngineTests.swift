import Foundation

// Simple test function to verify the rating logic
func testSleepRatingEngine() {
    let calendar = Calendar.current
    let now = Date()
    
    // Test data setup
    let goalHours = 8.0
    
    // Sleep windows: 10PM-11PM bedtime, 6AM-8AM wake
    let bedtimeStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now) ?? now
    let bedtimeEnd = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
    let wakeWindowStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
    let wakeWindowEnd = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
    
    // Test Case 1: Perfect - duration meets goal AND within windows
    let sleepStart1 = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: now) ?? now
    let sleepEnd1 = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: now) ?? now
    let duration1 = 8.0
    
    let rating1 = SleepRatingEngine.calculateRating(
        duration: duration1,
        goalHours: goalHours,
        sleepStart: sleepStart1,
        sleepEnd: sleepEnd1,
        bedtimeStart: bedtimeStart,
        bedtimeEnd: bedtimeEnd,
        wakeWindowStart: wakeWindowStart,
        wakeWindowEnd: wakeWindowEnd
    )
    
    print("Test 1 - Perfect: \(rating1.rawValue) (Expected: Perfect)")
    
    // Test Case 2: Good - duration meets goal but outside windows
    let sleepStart2 = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) ?? now
    let sleepEnd2 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
    let duration2 = 8.0
    
    let rating2 = SleepRatingEngine.calculateRating(
        duration: duration2,
        goalHours: goalHours,
        sleepStart: sleepStart2,
        sleepEnd: sleepEnd2,
        bedtimeStart: bedtimeStart,
        bedtimeEnd: bedtimeEnd,
        wakeWindowStart: wakeWindowStart,
        wakeWindowEnd: wakeWindowEnd
    )
    
    print("Test 2 - Good: \(rating2.rawValue) (Expected: Good)")
    
    // Test Case 3: OK - within 1 hour of goal
    let sleepStart3 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
    let sleepEnd3 = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
    let duration3 = 7.0
    
    let rating3 = SleepRatingEngine.calculateRating(
        duration: duration3,
        goalHours: goalHours,
        sleepStart: sleepStart3,
        sleepEnd: sleepEnd3,
        bedtimeStart: bedtimeStart,
        bedtimeEnd: bedtimeEnd,
        wakeWindowStart: wakeWindowStart,
        wakeWindowEnd: wakeWindowEnd
    )
    
    print("Test 3 - OK: \(rating3.rawValue) (Expected: OK)")
    
    // Test Case 4: Not Meet - more than 1 hour short of goal
    let sleepStart4 = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: now) ?? now
    let sleepEnd4 = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: now) ?? now
    let duration4 = 4.0
    
    let rating4 = SleepRatingEngine.calculateRating(
        duration: duration4,
        goalHours: goalHours,
        sleepStart: sleepStart4,
        sleepEnd: sleepEnd4,
        bedtimeStart: bedtimeStart,
        bedtimeEnd: bedtimeEnd,
        wakeWindowStart: wakeWindowStart,
        wakeWindowEnd: wakeWindowEnd
    )
    
    print("Test 4 - Not Meet: \(rating4.rawValue) (Expected: Not Meet)")
}

// Uncomment to run tests
// testSleepRatingEngine()

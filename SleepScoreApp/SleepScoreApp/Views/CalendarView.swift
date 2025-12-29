import SwiftUI

struct CalendarView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var goalManager = SleepGoalManager()
    @State private var selectedDate = Date()
    @State private var showingDetail = false
    @State private var currentMonth = Date()
    @State private var sleepDays: [SleepDay] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month header with navigation
                monthHeaderView
                
                // Calendar grid
                calendarGridView
                
                // Summary section
                summarySection
                
                Spacer()
            }
            .navigationTitle("Sleep Calendar")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let sleepDay = sleepDayForDate(selectedDate) {
                    NavigationView {
                        SleepDetailView(sleepDay: sleepDay)
                    }
                }
            }
            .onAppear {
                refreshData()
            }
            .onChange(of: healthKitManager.sleepData) { _ in
                convertHealthDataToSleepDays()
            }
        }
    }
    
    private var monthHeaderView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var calendarGridView: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(calendarDays, id: \.self) { dayInfo in
                    CalendarDayCell(
                        day: dayInfo.day,
                        sleepDay: dayInfo.sleepDay,
                        isCurrentMonth: dayInfo.isCurrentMonth,
                        isSelected: dayInfo.date,
                        calendarDate: currentMonth,
                        onTap: {
                            selectedDate = dayInfo.date ?? Date()
                            showingDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            if let todaySleep = sleepDayForDate(Date()) {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(formatTime(todaySleep.actualStart)) - \(formatTime(todaySleep.actualEnd))")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text(todaySleep.rating.rawValue)
                            .font(.subheadline)
                            .foregroundColor(todaySleep.rating.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(todaySleep.rating.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Good")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(monthlyStats.good)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Bad")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(monthlyStats.notMeet)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var calendarDays: [DayInfo] {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }
        
        var days: [DayInfo] = []
        let startWeekday = calendar.component(.weekday, from: monthStart) - 1
        
        // Add empty cells for days before month starts
        for _ in 0..<startWeekday {
            days.append(DayInfo(day: 0, isCurrentMonth: false, date: nil, sleepDay: nil))
        }
        
        // Add days of current month
        for day in monthRange {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
            let sleepDay = sleepDayForDate(date)
            days.append(DayInfo(day: day, isCurrentMonth: true, date: date, sleepDay: sleepDay))
        }
        
        return days
    }
    
    private var monthlyStats: (perfect: Int, good: Int, ok: Int, notMeet: Int) {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let monthEnd = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth
        
        let monthData = sleepDays.filter { sleepDay in
            sleepDay.date >= monthStart && sleepDay.date < monthEnd
        }
        
        return (
            perfect: monthData.filter { $0.rating == .perfect }.count,
            good: monthData.filter { $0.rating == .good }.count,
            ok: monthData.filter { $0.rating == .ok }.count,
            notMeet: monthData.filter { $0.rating == .not_meet }.count
        )
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() {
        healthKitManager.forceRefreshSleepData()
    }
    
    private func convertHealthDataToSleepDays() {
        let calendar = Calendar.current
        var convertedSleepDays: [SleepDay] = []
        
        // Group sleep records by their attributed day using the new logic
        let attributedRecords = Dictionary(grouping: healthKitManager.sleepData) { record in
            getAttributedSleepDay(for: record, with: goalManager.sleepGoal, calendar: calendar)
        }
        
        for (date, records) in attributedRecords {
            // Calculate total sleep duration for the day
            let totalDuration = records.reduce(0) { total, record in
                total + record.duration
            }
            
            // Find the earliest start time and latest end time
            let sortedRecords = records.sorted { $0.startDate < $1.startDate }
            let earliestStart = sortedRecords.first?.startDate ?? date
            let latestEnd = sortedRecords.last?.endDate ?? date
            
            // Create SleepDay with rating
            let sleepDay = SleepDay(
                date: date,
                actualStart: earliestStart,
                actualEnd: latestEnd,
                durationHours: totalDuration / 3600,
                source: .apple_watch,
                sleepGoal: goalManager.sleepGoal
            )
            
            convertedSleepDays.append(sleepDay)
        }
        
        sleepDays = convertedSleepDays.sorted { $0.date > $1.date }
    }
    
    private func getAttributedSleepDay(for record: SleepRecord, with goal: SleepGoal, calendar: Calendar) -> Date {
        let recordStart = record.startDate
        let recordEnd = record.endDate
        let currentDay = calendar.startOfDay(for: recordStart)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
        
        // Get sleep windows for current and previous day
        let currentDaySleepWindow = getSleepWindow(for: currentDay, with: goal, calendar: calendar)
        let previousDaySleepWindow = getSleepWindow(for: previousDay, with: goal, calendar: calendar)
        
        // Calculate overlap with previous day's sleep window
        let overlapWithPrevious = calculateOverlap(
            sessionStart: recordStart,
            sessionEnd: recordEnd,
            windowStart: previousDaySleepWindow.start,
            windowEnd: previousDaySleepWindow.end
        )
        
        // Calculate overlap with current day's sleep window
        let overlapWithCurrent = calculateOverlap(
            sessionStart: recordStart,
            sessionEnd: recordEnd,
            windowStart: currentDaySleepWindow.start,
            windowEnd: currentDaySleepWindow.end
        )
        
        // Apply attribution logic
        if overlapWithPrevious > 0 || recordStart < currentDaySleepWindow.end {
            return previousDay
        } else {
            return currentDay
        }
    }
    
    private func getSleepWindow(for date: Date, with goal: SleepGoal, calendar: Calendar) -> (start: Date, end: Date) {
        let bedtimeStart = combineDateWithTime(date: date, time: goal.bedtimeStart, calendar: calendar)
        let bedtimeEnd = combineDateWithTime(date: date, time: goal.bedtimeEnd, calendar: calendar)
        
        // Handle case where bedtime window spans midnight
        if bedtimeEnd < bedtimeStart {
            // Bedtime window goes to next day
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let adjustedEnd = combineDateWithTime(date: nextDay, time: goal.bedtimeEnd, calendar: calendar)
            return (bedtimeStart, adjustedEnd)
        } else {
            return (bedtimeStart, bedtimeEnd)
        }
    }
    
    private func combineDateWithTime(date: Date, time: Date, calendar: Calendar) -> Date {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? date
    }
    
    private func calculateOverlap(sessionStart: Date, sessionEnd: Date, windowStart: Date, windowEnd: Date) -> TimeInterval {
        let overlapStart = max(sessionStart, windowStart)
        let overlapEnd = min(sessionEnd, windowEnd)
        
        if overlapEnd > overlapStart {
            return overlapEnd.timeIntervalSince(overlapStart)
        } else {
            return 0
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func sleepDayForDate(_ date: Date) -> SleepDay? {
        return sleepDays.first { sleepDay in
            Calendar.current.isDate(sleepDay.date, inSameDayAs: date)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct DayInfo: Hashable {
    let day: Int
    let isCurrentMonth: Bool
    let date: Date?
    let sleepDay: SleepDay?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(day)
        hasher.combine(isCurrentMonth)
        hasher.combine(date)
        if let sleepDay = sleepDay {
            hasher.combine(sleepDay.id)
        }
    }
    
    static func == (lhs: DayInfo, rhs: DayInfo) -> Bool {
        return lhs.day == rhs.day &&
               lhs.isCurrentMonth == rhs.isCurrentMonth &&
               lhs.date == rhs.date &&
               lhs.sleepDay?.id == rhs.sleepDay?.id
    }
}

#Preview {
    CalendarView()
}

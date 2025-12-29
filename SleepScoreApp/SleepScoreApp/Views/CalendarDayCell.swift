import SwiftUI

struct CalendarDayCell: View {
    let day: Int
    let sleepDay: SleepDay?
    let isCurrentMonth: Bool
    let isSelected: Date?
    let calendarDate: Date // Add calendar date parameter
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background color based on rating
                if let sleepDay = sleepDay {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(sleepDay.rating.color.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(sleepDay.rating.color.opacity(0.5), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                }
                
                // Day number
                Text("\(day)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isCurrentMonth ? .primary : .secondary)
                
                // Selection indicator
                if let selected = isSelected,
                   Calendar.current.isDate(selected, inSameDayAs: dateForDay(day)) {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 2)
                }
            }
        }
        .frame(width: 40, height: 40)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func dateForDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        let currentMonth = calendar.dateComponents([.year, .month], from: calendarDate)
        return calendar.date(from: DateComponents(year: currentMonth.year, month: currentMonth.month, day: day)) ?? Date()
    }
}

#Preview {
    VStack(spacing: 8) {
        HStack(spacing: 4) {
            CalendarDayCell(day: 1, sleepDay: nil, isCurrentMonth: true, isSelected: nil, calendarDate: Date()) { }
            CalendarDayCell(day: 2, sleepDay: nil, isCurrentMonth: true, isSelected: nil, calendarDate: Date()) { }
            CalendarDayCell(day: 3, sleepDay: createSampleSleepDay(.perfect), isCurrentMonth: true, isSelected: nil, calendarDate: Date()) { }
            CalendarDayCell(day: 4, sleepDay: createSampleSleepDay(.good), isCurrentMonth: true, isSelected: nil, calendarDate: Date()) { }
            CalendarDayCell(day: 5, sleepDay: createSampleSleepDay(.ok), isCurrentMonth: true, isSelected: nil, calendarDate: Date()) { }
            CalendarDayCell(day: 6, sleepDay: createSampleSleepDay(.not_meet), isCurrentMonth: true, isSelected: nil, calendarDate: Date()) { }
        }
        
        Text("Perfect | Good | OK | Not Meet")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

private func createSampleSleepDay(_ rating: SleepRating) -> SleepDay {
    let calendar = Calendar.current
    let now = Date()
    
    return SleepDay(
        date: now,
        actualStart: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now) ?? now,
        actualEnd: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now,
        durationHours: 8.0,
        rating: rating,
        source: .apple_watch
    )
}

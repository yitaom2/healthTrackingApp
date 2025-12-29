import SwiftUI

struct DailySleepCardView: View {
    let sleepDay: SleepDay
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with date and rating
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(sleepDay.date))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(sleepDay.rating.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(sleepDay.rating.color.opacity(0.2))
                        .foregroundColor(sleepDay.rating.color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Duration
                Text("\(String(format: "%.1f", sleepDay.durationHours))h")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(sleepDay.rating.color)
            }
            
            // Sleep times
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bedtime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(sleepDay.actualStart))
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Wake")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(sleepDay.actualEnd))
                        .font(.headline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(16)
        .background(sleepDay.rating.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sleepDay.rating.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    
    let sampleSleepDay = SleepDay(
        date: now,
        actualStart: calendar.date(bySettingHour: 22, minute: 15, second: 0, of: now) ?? now,
        actualEnd: calendar.date(bySettingHour: 6, minute: 15, second: 0, of: now) ?? now,
        durationHours: 8.0,
        source: .apple_watch,
        sleepGoal: SleepGoal()
    )
    
    return DailySleepCardView(sleepDay: sampleSleepDay)
        .padding()
}

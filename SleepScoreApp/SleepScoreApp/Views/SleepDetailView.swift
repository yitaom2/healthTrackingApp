import SwiftUI

struct SleepDetailView: View {
    let sleepDay: SleepDay
    @State private var showingEditSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with rating
                VStack(spacing: 12) {
                    Text(formatDate(sleepDay.date))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(sleepDay.rating.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(sleepDay.rating.color.opacity(0.2))
                        .foregroundColor(sleepDay.rating.color)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
                
                // Main sleep card
                DailySleepCardView(sleepDay: sleepDay)
                
                // Detailed information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sleep Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        DetailRow(
                            title: "Duration",
                            value: "\(String(format: "%.2f", sleepDay.durationHours)) hours",
                            icon: "clock",
                            color: sleepDay.rating.color
                        )
                        
                        DetailRow(
                            title: "Bedtime",
                            value: formatTime(sleepDay.actualStart),
                            icon: "moon.fill",
                            color: .blue
                        )
                        
                        DetailRow(
                            title: "Wake Time",
                            value: formatTime(sleepDay.actualEnd),
                            icon: "sunrise.fill",
                            color: .orange
                        )
                        
                        DetailRow(
                            title: "Source",
                            value: sleepDay.source.rawValue,
                            icon: "applewatch",
                            color: .gray
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Rating explanation
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rating Criteria")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(ratingExplanation)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Sleep Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSleepView(sleepDay: sleepDay) { updatedSleepDay in
                // Handle the updated sleep day
                dismiss()
            }
        }
    }
    
    private var ratingExplanation: String {
        switch sleepDay.rating {
        case .perfect:
            return "Perfect! You met your sleep goal and slept within your preferred time window."
        case .good:
            return "Good job! You met your sleep duration goal, but slept outside your preferred time window."
        case .ok:
            return "Almost there! You were within 1 hour of your sleep goal."
        case .not_meet:
            return "Keep trying! You were more than 1 hour short of your sleep goal."
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Edit Sleep View

struct EditSleepView: View {
    let sleepDay: SleepDay
    let onSave: (SleepDay) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var bedtime: Date
    @State private var wakeTime: Date
    
    init(sleepDay: SleepDay, onSave: @escaping (SleepDay) -> Void) {
        self.sleepDay = sleepDay
        self.onSave = onSave
        self._bedtime = State(initialValue: sleepDay.actualStart)
        self._wakeTime = State(initialValue: sleepDay.actualEnd)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sleep Times") {
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Summary") {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(String(format: "%.2f", calculatedDuration)) hours")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSleep()
                    }
                }
            }
        }
    }
    
    private var calculatedDuration: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: bedtime, to: wakeTime)
        return Double(components.minute ?? 0) / 60.0
    }
    
    private func saveSleep() {
        let updatedSleepDay = SleepDay(
            date: sleepDay.date,
            actualStart: bedtime,
            actualEnd: wakeTime,
            durationHours: calculatedDuration,
            source: .manual,
            sleepGoal: SleepGoal() // This should come from the actual goal manager
        )
        
        onSave(updatedSleepDay)
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
    
    return NavigationView {
        SleepDetailView(sleepDay: sampleSleepDay)
    }
}

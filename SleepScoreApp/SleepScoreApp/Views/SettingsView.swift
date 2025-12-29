import SwiftUI

struct SettingsView: View {
    @ObservedObject var goalManager: SleepGoalManager
    
    var body: some View {
        Form {
            Section(header: Text("Sleep Goals")) {
                NavigationLink("Set Sleep Goals") {
                    SleepGoalSetupView(goalManager: goalManager)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Bedtime: \(formatTime(goalManager.sleepGoal.bedtimeStart)) - \(formatTime(goalManager.sleepGoal.bedtimeEnd))")
                    Text("Wake: \(formatTime(goalManager.sleepGoal.wakeWindowStart)) - \(formatTime(goalManager.sleepGoal.wakeWindowEnd))")
                    Text("Target: \(String(format: "%.2f", goalManager.sleepGoal.targetSleepHours)) hours")
                }
                .font(.footnote)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        SettingsView(goalManager: SleepGoalManager())
    }
}

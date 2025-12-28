import SwiftUI

struct SleepGoalSetupView: View {
    @ObservedObject var goalManager: SleepGoalManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempGoal: SleepGoal
    
    init(goalManager: SleepGoalManager) {
        self.goalManager = goalManager
        self._tempGoal = State(initialValue: goalManager.sleepGoal)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bedtime Window")) {
                    DatePicker("Start Time", selection: $tempGoal.bedtimeStart, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $tempGoal.bedtimeEnd, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Wake Window")) {
                    DatePicker("Start Time", selection: $tempGoal.wakeWindowStart, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $tempGoal.wakeWindowEnd, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Daily Target")) {
                    HStack {
                        Text("Target Sleep Hours")
                        Spacer()
                        TextField("Hours", value: $tempGoal.targetSleepHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("hours")
                    }
                }
                
                Section {
                    Button("Save Sleep Goals") {
                        goalManager.updateSleepGoal(tempGoal)
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Sleep Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

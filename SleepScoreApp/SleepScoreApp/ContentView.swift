//
//  ContentView.swift
//  SleepScoreApp
//
//  Created by Yitao Meng on 12/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var goalManager = SleepGoalManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SleepScore Lite")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Text("Daily Sleep Rating (Coming Soon)")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // Current Sleep Goals Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Sleep Goals")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.blue)
                            Text("Bedtime: \(formatTime(goalManager.sleepGoal.bedtimeStart)) - \(formatTime(goalManager.sleepGoal.bedtimeEnd))")
                        }
                        
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(.orange)
                            Text("Wake: \(formatTime(goalManager.sleepGoal.wakeWindowStart)) - \(formatTime(goalManager.sleepGoal.wakeWindowEnd))")
                        }
                        
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.green)
                            Text("Target: \(String(format: "%.1f", goalManager.sleepGoal.targetSleepHours)) hours")
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Settings") {
                        SettingsView(goalManager: goalManager)
                    }
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}

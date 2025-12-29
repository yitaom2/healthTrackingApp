//
//  ContentView.swift
//  SleepScoreApp
//
//  Created by Yitao Meng on 12/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var goalManager = SleepGoalManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var showingSettings = false
    @State private var showingSleepData = false
    @State private var showingCalendar = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("SleepScore Lite")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 50)
                    
                    // Daily Sleep Card
                    if let latestSleepDay = getLatestSleepDay() {
                        DailySleepCardView(sleepDay: latestSleepDay)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "moon.zzz")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No sleep data available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Connect your Apple Watch or enable sleep tracking to see your sleep data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
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
                                Text("Target: \(String(format: "%.2f", goalManager.sleepGoal.targetSleepHours)) hours")
                            }
                        }
                        .font(.subheadline)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            showingCalendar = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                Text("View Calendar")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Settings") {
                            showingSettings = true
                        }
                        Button("Sleep Data") {
                            showingSleepData = true
                        }
                        Button("Calendar") {
                            showingCalendar = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    SettingsView(goalManager: goalManager)
                }
            }
            .sheet(isPresented: $showingSleepData) {
                NavigationView {
                    SleepDataView()
                }
            }
            .fullScreenCover(isPresented: $showingCalendar) {
                CalendarView()
            }
            .onAppear {
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        healthKitManager.forceRefreshSleepData()
    }
    
    private func getLatestSleepDay() -> SleepDay? {
        guard !healthKitManager.sleepData.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let groupedRecords = Dictionary(grouping: healthKitManager.sleepData) { record in
            calendar.startOfDay(for: record.startDate)
        }
        
        // Get the most recent day with sleep data
        let mostRecentDate = groupedRecords.keys.sorted(by: >).first
        
        guard let date = mostRecentDate,
              let records = groupedRecords[date],
              !records.isEmpty else { return nil }
        
        // Calculate total sleep duration for the day
        let totalDuration = records.reduce(0) { total, record in
            total + record.duration
        }
        
        // Find the earliest start time and latest end time
        let sortedRecords = records.sorted { $0.startDate < $1.startDate }
        let earliestStart = sortedRecords.first?.startDate ?? date
        let latestEnd = sortedRecords.last?.endDate ?? date
        
        // Create SleepDay with rating
        return SleepDay(
            date: date,
            actualStart: earliestStart,
            actualEnd: latestEnd,
            durationHours: totalDuration / 3600,
            source: .apple_watch,
            sleepGoal: goalManager.sleepGoal
        )
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

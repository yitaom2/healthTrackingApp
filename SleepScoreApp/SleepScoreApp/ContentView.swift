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
        
        // Group sleep records by their attributed day using the same logic as CalendarView
        let attributedRecords = Dictionary(grouping: healthKitManager.sleepData) { record in
            getAttributedSleepDay(for: record, with: goalManager.sleepGoal, calendar: calendar)
        }
        
        // Get the most recent day with sleep data
        let mostRecentDate = attributedRecords.keys.sorted(by: >).first
        
        guard let date = mostRecentDate,
              let records = attributedRecords[date],
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
    
    private func getAttributedSleepDay(for record: SleepRecord, with goal: SleepGoal, calendar: Calendar) -> Date {
        let recordStart = record.startDate
        let recordEnd = record.endDate
        let currentDay = calendar.startOfDay(for: recordStart)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
        
        // Check if sleep session starts in early morning hours (before 6 AM)
        let startHour = calendar.component(.hour, from: recordStart)
        let startMinute = calendar.component(.minute, from: recordStart)
        let totalStartMinutes = startHour * 60 + startMinute
        
        print("CONTENT DEBUG: Sleep session \(recordStart) - \(recordEnd)")
        print("CONTENT DEBUG: Start time: \(startHour):\(String(format: "%02d", startMinute)) (\(totalStartMinutes) minutes)")
        print("CONTENT DEBUG: Current day: \(currentDay), Previous day: \(previousDay)")
        
        // If sleep starts before 6 AM (360 minutes), attribute to previous day
        if totalStartMinutes < 360 {
            print("CONTENT DEBUG: Early morning rule applied - attributing to previous day: \(previousDay)")
            return previousDay
        }
        
        print("CONTENT DEBUG: Not early morning, checking sleep windows...")
        
        // Get sleep windows for current and previous day
        let currentDaySleepWindow = getSleepWindow(for: currentDay, with: goal, calendar: calendar)
        let previousDaySleepWindow = getSleepWindow(for: previousDay, with: goal, calendar: calendar)
        
        print("CONTENT DEBUG: Current day sleep window: \(currentDaySleepWindow.start) - \(currentDaySleepWindow.end)")
        print("CONTENT DEBUG: Previous day sleep window: \(previousDaySleepWindow.start) - \(previousDaySleepWindow.end)")
        
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
        
        print("CONTENT DEBUG: Overlap with previous: \(overlapWithPrevious)s, overlap with current: \(overlapWithCurrent)s")
        print("CONTENT DEBUG: Record start < current window end: \(recordStart < currentDaySleepWindow.end)")
        
        // Apply attribution logic
        if overlapWithPrevious > 0 || recordStart < currentDaySleepWindow.end {
            print("CONTENT DEBUG: Attribution logic applied - attributing to previous day: \(previousDay)")
            return previousDay
        } else {
            print("CONTENT DEBUG: No attribution conditions met - attributing to current day: \(currentDay)")
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}

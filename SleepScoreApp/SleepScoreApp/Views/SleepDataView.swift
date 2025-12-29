import SwiftUI

struct SleepDataView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some View {
        VStack {
            if !healthKitManager.isAuthorized {
                authorizationView
            } else if let errorMessage = healthKitManager.errorMessage {
                errorView(errorMessage)
            } else {
                sleepDataList
            }
        }
        .navigationTitle("Sleep Data")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    healthKitManager.fetchSleepData()
                }
            }
        }
    }
    
    private var authorizationView: some View {
        VStack(spacing: 20) {
            Text("HealthKit Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This app needs access to your sleep data from Apple Health to provide personalized insights and ratings.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Request Access") {
                healthKitManager.requestHealthKitPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Try Again") {
                healthKitManager.fetchSleepData()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var sleepDataList: some View {
        List(healthKitManager.sleepData, id: \.startDate) { record in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(formatDate(record.startDate))
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(formatDuration(record.duration))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Start: \(formatTime(record.startDate))")
                    Spacer()
                    Text("End: \(formatTime(record.endDate))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("Source: \(record.source)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SleepDataView_Previews: PreviewProvider {
    static var previews: some View {
        SleepDataView()
    }
}

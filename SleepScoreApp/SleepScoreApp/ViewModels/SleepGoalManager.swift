import Foundation
import Combine

class SleepGoalManager: ObservableObject {
    @Published var sleepGoal: SleepGoal {
        didSet {
            saveSleepGoal()
        }
    }
    
    private let sleepGoalKey = "SleepGoal"
    
    init() {
        if let savedData = UserDefaults.standard.data(forKey: sleepGoalKey),
           let decodedGoal = try? JSONDecoder().decode(SleepGoal.self, from: savedData) {
            self.sleepGoal = decodedGoal
        } else {
            self.sleepGoal = SleepGoal()
        }
    }
    
    private func saveSleepGoal() {
        if let encodedData = try? JSONEncoder().encode(sleepGoal) {
            UserDefaults.standard.set(encodedData, forKey: sleepGoalKey)
        }
    }
    
    func updateSleepGoal(_ newGoal: SleepGoal) {
        sleepGoal = newGoal
    }
}

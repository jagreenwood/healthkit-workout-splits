import Foundation
import HealthKit
import Observation

/// View model for the workout list screen
@Observable
@MainActor
class WorkoutListViewModel {
    var workouts: [HKWorkout] = []
    var isLoading = false
    var errorMessage: String?
    var isAuthorized = false

    private let healthKitManager = HealthKitManager()

    /// Request HealthKit authorization
    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil

        do {
            try await healthKitManager.requestAuthorization()
            isAuthorized = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthorized = false
        }

        isLoading = false
    }

    /// Load workouts from the last 30 days, filtering for those with distance data
    func loadWorkouts() async {
        guard isAuthorized else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Calculate start date (30 days ago)
            guard let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
                throw NSError(domain: "WorkoutListViewModel", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to calculate start date"
                ])
            }

            // Fetch workouts
            let allWorkouts = try await healthKitManager.fetchWorkouts(from: startDate)

            // Filter to only include workouts with distance data
            workouts = allWorkouts.filter { workout in
                guard let distance = workout.totalDistance else { return false }
                return distance.doubleValue(for: .meter()) > 0
            }
        } catch {
            errorMessage = error.localizedDescription
            workouts = []
        }

        isLoading = false
    }
}

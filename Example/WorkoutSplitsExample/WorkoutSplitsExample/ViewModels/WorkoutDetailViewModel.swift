import Foundation
import HealthKit
import HealthKitWorkoutSplits
import Observation

/// View model for the workout detail screen
@Observable
@MainActor
class WorkoutDetailViewModel {
    var splits: [WorkoutSplit] = []
    var isLoading = false
    var errorMessage: String?

    private let healthKitManager = HealthKitManager()
    let workout: HKWorkout

    init(workout: HKWorkout) {
        self.workout = workout
    }

    /// Calculate splits for the workout
    func loadSplits() async {
        isLoading = true
        errorMessage = nil

        do {
            splits = try await healthKitManager.calculateSplits(for: workout)
        } catch let error as SplitCalculatorError {
            errorMessage = error.errorDescription
        } catch {
            // Handle other errors
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

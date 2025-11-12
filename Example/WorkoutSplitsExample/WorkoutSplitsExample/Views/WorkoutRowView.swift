import SwiftUI
import HealthKit
import HealthKitWorkoutSplits

/// Row view displaying workout information in the list
struct WorkoutRowView: View {
    let workout: HKWorkout

    var body: some View {
        HStack(spacing: 12) {
            // Workout type icon
            Image(systemName: workoutIcon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                // Workout type name
                Text(workout.activityName)
                    .font(.headline)

                // Date
                Text(formatDate(workout.startDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Distance and duration
                HStack(spacing: 8) {
                    if let distance = workout.totalDistance {
                        Text(formatDistance(distance))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let distance = workout.totalDistance, distance.doubleValue(for: .meter()) > 0 {
                        Text("•")
                            .foregroundStyle(.secondary)
                    }

                    Text(formatDuration(workout.activeDuration))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper Properties and Methods

    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "figure.outdoor.cycle"
        case .swimming:
            return "figure.pool.swim"
        case .hiking:
            return "figure.hiking"
        default:
            return "figure.mixed.cardio"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }

    private func formatDistance(_ quantity: HKQuantity) -> String {
        let miles = quantity.doubleValue(for: .mile())
        return String(format: "%.2f mi", miles)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

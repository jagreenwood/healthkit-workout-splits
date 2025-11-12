import SwiftUI
import HealthKitWorkoutSplits

/// Row view displaying split information
struct SplitRowView: View {
    let split: WorkoutSplit

    var body: some View {
        HStack(alignment: .center) {
            // Split number with partial indicator
            VStack(alignment: .leading, spacing: 2) {
                Text(splitLabel)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if split.isPartial {
                    Text(partialDistanceLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Time and pace
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(split.duration))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(formatPace(split.minutesPerMile))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helper Properties and Methods

    private var splitLabel: String {
        if split.isPartial {
            return "Mile \(split.splitNumber) (Partial)"
        } else {
            return "Mile \(split.splitNumber)"
        }
    }

    private var partialDistanceLabel: String {
        let miles = split.distance.converted(to: .miles).value
        return String(format: "%.2f mi", miles)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatPace(_ minutesPerMile: Double) -> String {
        let minutes = Int(minutesPerMile)
        let seconds = Int((minutesPerMile - Double(minutes)) * 60)
        return String(format: "%d:%02d /mi", minutes, seconds)
    }
}

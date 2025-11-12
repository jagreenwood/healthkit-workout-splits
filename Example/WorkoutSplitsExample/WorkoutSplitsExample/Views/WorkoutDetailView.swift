import SwiftUI
import HealthKit
import HealthKitWorkoutSplits

/// Detail view displaying workout information and calculated splits
struct WorkoutDetailView: View {
    let workout: HKWorkout
    @State private var viewModel: WorkoutDetailViewModel

    init(workout: HKWorkout) {
        self.workout = workout
        self._viewModel = State(initialValue: WorkoutDetailViewModel(workout: workout))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Workout Summary Section
                workoutSummarySection

                // Splits Section
                splitsSection
            }
            .padding()
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSplits()
        }
    }

    // MARK: - Workout Summary Section

    private var workoutSummarySection: some View {
        VStack(spacing: 16) {
            // Workout icon and name
            HStack(spacing: 12) {
                Image(systemName: workoutIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.activityName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(formatDate(workout.startDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Workout stats
            HStack(spacing: 20) {
                statBox(
                    icon: "figure.run",
                    label: "Distance",
                    value: formatDistance(workout.totalDistance)
                )

                statBox(
                    icon: "clock",
                    label: "Duration",
                    value: formatDuration(workout.activeDuration)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func statBox(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Splits Section

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("1-Mile Splits")
                .font(.title3)
                .fontWeight(.bold)

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Calculating splits...")
                        .padding()
                    Spacer()
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)

                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else if viewModel.splits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("No splits calculated")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.splits, id: \.splitNumber) { split in
                        SplitRowView(split: split)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
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
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDistance(_ quantity: HKQuantity?) -> String {
        guard let quantity = quantity else { return "N/A" }
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

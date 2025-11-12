import SwiftUI
import HealthKit

/// Main view displaying a list of workouts from the last 30 days
struct WorkoutListView: View {
    @State private var viewModel = WorkoutListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.workouts.isEmpty {
                    ProgressView("Loading workouts...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.red)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task {
                                await viewModel.requestAuthorization()
                                await viewModel.loadWorkouts()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if viewModel.workouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Workouts Found")
                            .font(.headline)
                        Text("No workouts with distance data found in the last 30 days. Make sure you've granted permission in Settings.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List(viewModel.workouts, id: \.uuid) { workout in
                        NavigationLink(value: workout) {
                            WorkoutRowView(workout: workout)
                        }
                    }
                    .navigationDestination(for: HKWorkout.self) { workout in
                        WorkoutDetailView(workout: workout)
                    }
                }
            }
            .navigationTitle("Workouts")
            .task {
                await viewModel.requestAuthorization()
                await viewModel.loadWorkouts()
            }
        }
    }
}

#Preview {
    WorkoutListView()
}

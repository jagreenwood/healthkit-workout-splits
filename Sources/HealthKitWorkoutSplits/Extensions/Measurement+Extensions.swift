import Foundation

// MARK: - UnitSpeed Extensions

extension UnitSpeed {
    /// Minutes per mile (inverse of miles per hour)
    ///
    /// Useful for displaying running/walking pace in the common "min/mile" format
    public static var minutesPerMile: UnitSpeed {
        return UnitSpeed(symbol: "min/mi", converter: UnitConverterLinear(coefficient: 26.8224))
    }

    /// Minutes per kilometer (inverse of kilometers per hour)
    ///
    /// Useful for displaying running/walking pace in the common "min/km" format
    public static var minutesPerKilometer: UnitSpeed {
        return UnitSpeed(symbol: "min/km", converter: UnitConverterLinear(coefficient: 16.6667))
    }
}

// MARK: - Measurement<UnitSpeed> Extensions

extension Measurement where UnitType == UnitSpeed {
    /// Converts pace to minutes per mile
    ///
    /// Example:
    /// ```swift
    /// let pace = Measurement(value: 3.35, unit: UnitSpeed.metersPerSecond)
    /// let minPerMile = pace.minutesPerMile  // ~8.0
    /// ```
    public var minutesPerMile: Double {
        let milesPerHour = self.converted(to: .milesPerHour).value
        guard milesPerHour > 0 else { return 0 }
        return 60.0 / milesPerHour
    }

    /// Converts pace to minutes per kilometer
    ///
    /// Example:
    /// ```swift
    /// let pace = Measurement(value: 3.35, unit: UnitSpeed.metersPerSecond)
    /// let minPerKm = pace.minutesPerKilometer  // ~5.0
    /// ```
    public var minutesPerKilometer: Double {
        let kilometersPerHour = self.converted(to: .kilometersPerHour).value
        guard kilometersPerHour > 0 else { return 0 }
        return 60.0 / kilometersPerHour
    }

    /// Formats pace as a readable string (e.g., "8:30 /mi")
    ///
    /// - Parameter unit: The distance unit for pace (miles or kilometers)
    /// - Returns: Formatted pace string (e.g., "8:30 /mi" or "5:15 /km")
    public func formattedPace(per unit: UnitLength) -> String {
        let minutesPerUnit: Double
        let unitString: String

        switch unit {
        case .miles:
            minutesPerUnit = self.minutesPerMile
            unitString = "mi"
        case .kilometers:
            minutesPerUnit = self.minutesPerKilometer
            unitString = "km"
        default:
            // For other units, convert to meters and format
            let metersPerSecond = self.converted(to: .metersPerSecond).value
            guard metersPerSecond > 0 else { return "0:00" }
            return String(format: "%.2f m/s", metersPerSecond)
        }

        let minutes = Int(minutesPerUnit)
        let seconds = Int((minutesPerUnit - Double(minutes)) * 60)

        return String(format: "%d:%02d /%@", minutes, seconds, unitString)
    }
}

// MARK: - Measurement<UnitLength> Extensions

extension Measurement where UnitType == UnitLength {
    /// Formats distance as a readable string
    ///
    /// - Parameter maxFractionDigits: Maximum number of decimal places (default: 2)
    /// - Returns: Formatted distance string (e.g., "5.25 mi" or "8.45 km")
    public func formattedDistance(maxFractionDigits: Int = 2) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = maxFractionDigits
        return formatter.string(from: self)
    }
}

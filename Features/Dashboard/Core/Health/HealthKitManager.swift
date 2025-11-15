// In Core/Health/HealthKitManager.swift
import Foundation
import HealthKit

class HealthKitManager {
    let healthStore = HKHealthStore()

    // Function to request authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            // Basic activity
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            
            // Heart metrics
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            
            // Body measurements
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .leanBodyMass)!,
            
            // Activity & wellness
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToShare: Set<HKSampleType> = []
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        print("HealthKit Authorization Requested.") // Added log
    }

    // ✅ Renamed function to match HealthClient expectation: fetchDailyMetrics
    func fetchDailyMetrics() async -> [HealthMetric] {
        print("Fetching daily metrics...") // Added log
        var metrics: [HealthMetric] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()

        // Basic Activity
        if let steps = await fetchQuantityData(for: .stepCount, from: today, to: now) {
            metrics.append(HealthMetric(type: .steps, value: steps, date: now))
        }
        
        if let calories = await fetchQuantityData(for: .activeEnergyBurned, from: today, to: now) {
            metrics.append(HealthMetric(type: .calories, value: calories, date: now))
        }
        
        if let distance = await fetchQuantityData(for: .distanceWalkingRunning, from: today, to: now, unit: .meterUnit(with: .kilo)) {
            metrics.append(HealthMetric(type: .distance, value: distance, date: now))
        }
        
        if let flights = await fetchQuantityData(for: .flightsClimbed, from: today, to: now) {
            metrics.append(HealthMetric(type: .flightsClimbed, value: flights, date: now))
        }
        
        // Exercise & Stand Time
        if let exerciseTime = await fetchQuantityData(for: .appleExerciseTime, from: today, to: now, unit: .minute()) {
            metrics.append(HealthMetric(type: .exerciseTime, value: exerciseTime, date: now))
        }
        
        if let standTime = await fetchQuantityData(for: .appleStandTime, from: today, to: now, unit: .hour()) {
            metrics.append(HealthMetric(type: .standHours, value: standTime, date: now))
        }
        
        // Heart Metrics
        if let heartRate = await fetchLatestQuantitySample(for: .heartRate) {
            metrics.append(HealthMetric(type: .heartRate, value: heartRate, date: now))
        }
        
        if let restingHR = await fetchLatestQuantitySample(for: .restingHeartRate) {
            metrics.append(HealthMetric(type: .restingHeartRate, value: restingHR, date: now))
        }
        
        if let hrv = await fetchLatestQuantitySample(for: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) {
            metrics.append(HealthMetric(type: .heartRateVariability, value: hrv, date: now))
        }
        
        if let vo2 = await fetchLatestQuantitySample(for: .vo2Max, unit: HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute()))) {
            metrics.append(HealthMetric(type: .vo2Max, value: vo2, date: now))
        }
        
        if let breathing = await fetchLatestQuantitySample(for: .respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            metrics.append(HealthMetric(type: .respiratoryRate, value: breathing, date: now))
        }
        
        // Body Measurements
        if let weight = await fetchLatestQuantitySample(for: .bodyMass, unit: .gramUnit(with: .kilo)) {
            metrics.append(HealthMetric(type: .bodyMass, value: weight, date: now))
        }
        
        if let bodyFat = await fetchLatestQuantitySample(for: .bodyFatPercentage, unit: .percent()) {
            metrics.append(HealthMetric(type: .bodyFatPercentage, value: bodyFat * 100, date: now))
        }
        
        if let leanMass = await fetchLatestQuantitySample(for: .leanBodyMass, unit: .gramUnit(with: .kilo)) {
            metrics.append(HealthMetric(type: .leanBodyMass, value: leanMass, date: now))
        }
        
        // Mindfulness
        if let mindful = await fetchMindfulMinutes(from: today, to: now) {
            metrics.append(HealthMetric(type: .mindfulMinutes, value: mindful, date: now))
        }
        
        // Sleep
        if let sleep = await fetchSleepHours(from: today, to: now) {
            metrics.append(HealthMetric(type: .sleepHours, value: sleep, date: now))
        }

        print("Finished fetching daily metrics. Count: \(metrics.count)") // Added log
        return metrics
    }

    // ✅ Renamed function to match HealthClient expectation: fetchWeeklyStepData
    func fetchWeeklyStepData() async -> [StepData] {
        print("Fetching weekly step data...") // Added log
        var weeklyData: [StepData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let steps = await fetchQuantityData(for: .stepCount, from: dayStart, to: dayEnd, options: .cumulativeSum) ?? 0.0
            weeklyData.append(StepData(date: dayStart, count: steps))
        }
        
        print("Finished fetching weekly steps. Count: \(weeklyData.count)") // Added log
        return weeklyData.sorted { $0.date < $1.date }
    }

    func fetchWeeklyActiveEnergy() async -> [EnergyData] {
        print("Fetching weekly active energy...")
        var weeklyData: [EnergyData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let energy = await fetchQuantityData(for: .activeEnergyBurned, from: dayStart, to: dayEnd, options: .cumulativeSum) ?? 0.0
            weeklyData.append(EnergyData(date: dayStart, value: energy))
        }

        print("Finished fetching weekly active energy. Count: \(weeklyData.count)")
        return weeklyData.sorted { $0.date < $1.date }
    }

    func fetchWeeklyHeartRate() async -> [HeartRateData] {
        print("Fetching weekly heart rate...")
        var weeklyData: [HeartRateData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let heartRate = await fetchQuantityData(for: .heartRate, from: dayStart, to: dayEnd, options: .discreteAverage) ?? 0.0
            weeklyData.append(HeartRateData(date: dayStart, value: heartRate))
        }

        print("Finished fetching weekly heart rate. Count: \(weeklyData.count)")
        return weeklyData.sorted { $0.date < $1.date }
    }

    // --- Helper Functions ---
    private func fetchQuantityData(for typeIdentifier: HKQuantityTypeIdentifier, from start: Date, to end: Date, options: HKStatisticsOptions = .cumulativeSum, unit: HKUnit? = nil) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            print("Error: Invalid quantity type identifier: \(typeIdentifier.rawValue)")
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let queryDescriptor = HKSampleQueryDescriptor(predicates: [.sample(type: quantityType, predicate: predicate)], sortDescriptors: [])
        
        do {
            let results = try await queryDescriptor.result(for: healthStore)
            var totalValue: Double = 0
            for sample in results {
                if let quantitySample = sample as? HKQuantitySample {
                    let targetUnit: HKUnit
                    if let unit = unit {
                        targetUnit = unit
                    } else {
                        switch typeIdentifier {
                        case .stepCount, .flightsClimbed: targetUnit = .count()
                        case .activeEnergyBurned: targetUnit = .kilocalorie()
                        case .distanceWalkingRunning, .distanceCycling: targetUnit = .meterUnit(with: .kilo)
                        case .distanceSwimming: targetUnit = .meter()
                        case .appleExerciseTime: targetUnit = .minute()
                        case .appleStandTime: targetUnit = .hour()
                        case .heartRate: targetUnit = HKUnit.count().unitDivided(by: .minute())
                        default: targetUnit = HKUnit.count()
                        }
                    }
                    totalValue += quantitySample.quantity.doubleValue(for: targetUnit)
                }
            }
            return totalValue
        } catch {
            print("Error fetching quantity data for \(typeIdentifier.rawValue): \(error)")
            return nil
        }
    }
    
    private func fetchLatestQuantitySample(for typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit? = nil) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            print("Error: Invalid quantity type identifier: \(typeIdentifier.rawValue)")
            return nil
        }
        
        let queryDescriptor = HKSampleQueryDescriptor(
            predicates: [.sample(type: quantityType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        
        do {
            let results = try await queryDescriptor.result(for: healthStore)
            guard let sample = results.first as? HKQuantitySample else { return nil }
            
            let targetUnit: HKUnit
            if let unit = unit {
                targetUnit = unit
            } else {
                switch typeIdentifier {
                case .heartRate, .restingHeartRate, .respiratoryRate: 
                    targetUnit = HKUnit.count().unitDivided(by: .minute())
                case .bodyMass, .leanBodyMass: 
                    targetUnit = .gramUnit(with: .kilo)
                case .bodyFatPercentage: 
                    targetUnit = .percent()
                case .heartRateVariabilitySDNN: 
                    targetUnit = .secondUnit(with: .milli)
                default: 
                    targetUnit = HKUnit.count()
                }
            }
            return sample.quantity.doubleValue(for: targetUnit)
        } catch {
            print("Error fetching latest sample for \(typeIdentifier.rawValue): \(error)")
            return nil
        }
    }
    
    private func fetchMindfulMinutes(from start: Date, to end: Date) async -> Double? {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let queryDescriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: mindfulType, predicate: predicate)],
            sortDescriptors: []
        )
        
        do {
            let results = try await queryDescriptor.result(for: healthStore)
            var totalMinutes: Double = 0
            for sample in results {
                let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60
                totalMinutes += duration
            }
            return totalMinutes
        } catch {
            print("Error fetching mindful minutes: \(error)")
            return nil
        }
    }
    
    private func fetchSleepHours(from start: Date, to end: Date) async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let queryDescriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: []
        )
        
        do {
            let results = try await queryDescriptor.result(for: healthStore)
            var totalHours: Double = 0
            for sample in results {
                if let categorySample = sample as? HKCategorySample {
                    if categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                       categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                        totalHours += duration
                    }
                }
            }
            return totalHours
        } catch {
            print("Error fetching sleep hours: \(error)")
            return nil
        }
    }

    enum HealthKitError: Error {
        case healthDataNotAvailable
    }
}

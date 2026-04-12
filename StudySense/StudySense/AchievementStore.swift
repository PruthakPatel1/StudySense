//
//  AchievementStore.swift
//  StudySense
//
//  Created by Pruthak Patel on 4/12/26.

import Foundation
import Combine

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String           // SF Symbol
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }
}

@MainActor
final class AchievementStore: ObservableObject {

    @Published private(set) var achievements: [Achievement] = AchievementStore.defaultAchievements
    @Published var newlyUnlocked: [Achievement] = []

    private let key = "studysense.achievements"
    private let goalKey = "studysense.weeklyGoalHours"

    @Published var weeklyGoalHours: Double {
        didSet { UserDefaults.standard.set(weeklyGoalHours, forKey: goalKey) }
    }

    init() {
        weeklyGoalHours = UserDefaults.standard.double(forKey: "studysense.weeklyGoalHours")
        if weeklyGoalHours == 0 { weeklyGoalHours = 10 }
        load()
    }

    // MARK: - Evaluate after every session

    func evaluate(against store: SessionStore) {
        newlyUnlocked = []
        let sessions = store.sessions
        let totalHours = store.totalStudyHours
        let totalSessions = store.totalSessions
        let streak = store.streak

        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }
            let shouldUnlock: Bool

            switch achievements[i].id {
            // Streak milestones
            case "streak_3":    shouldUnlock = streak >= 3
            case "streak_7":    shouldUnlock = streak >= 7
            case "streak_30":   shouldUnlock = streak >= 30
            case "streak_100":  shouldUnlock = streak >= 100
            // Session count
            case "sessions_1":   shouldUnlock = totalSessions >= 1
            case "sessions_10":  shouldUnlock = totalSessions >= 10
            case "sessions_50":  shouldUnlock = totalSessions >= 50
            case "sessions_100": shouldUnlock = totalSessions >= 100
            // Total hours
            case "hours_1":   shouldUnlock = totalHours >= 1
            case "hours_10":  shouldUnlock = totalHours >= 10
            case "hours_50":  shouldUnlock = totalHours >= 50
            case "hours_100": shouldUnlock = totalHours >= 100
            // Perfect score
            case "perfect_score": shouldUnlock = sessions.contains { $0.focusScore == 100 }
            // Consistency — 7 unique calendar days in any rolling 7-day window
            case "consistency_week":
                let cal = Calendar.current
                let days = Set(sessions.map { cal.startOfDay(for: $0.date) })
                let today = cal.startOfDay(for: Date())
                shouldUnlock = (0..<7).allSatisfy { offset in
                    guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return false }
                    return days.contains(d)
                }
            default: shouldUnlock = false
            }

            if shouldUnlock {
                achievements[i].unlockedAt = Date()
                newlyUnlocked.append(achievements[i])
            }
        }

        persist()
    }

    // MARK: - Weekly progress

    func weeklyStudyHours(from store: SessionStore) -> Double {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return store.sessions
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.elapsedTime } / 3600
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Achievement].self, from: data)
        else { return }
        // Merge saved unlock dates into the default list so new achievements added in updates appear
        for i in achievements.indices {
            if let saved = decoded.first(where: { $0.id == achievements[i].id }) {
                achievements[i].unlockedAt = saved.unlockedAt
            }
        }
    }

    // MARK: - Achievement definitions

    static let defaultAchievements: [Achievement] = [
        // Streak
        Achievement(id: "streak_3",   title: "Hat Trick",      description: "3-day study streak",   icon: "flame"),
        Achievement(id: "streak_7",   title: "Week Warrior",   description: "7-day study streak",   icon: "flame.fill"),
        Achievement(id: "streak_30",  title: "Monthly Grind",  description: "30-day study streak",  icon: "calendar"),
        Achievement(id: "streak_100", title: "Centurion",      description: "100-day study streak", icon: "crown.fill"),
        // Sessions
        Achievement(id: "sessions_1",   title: "First Step",    description: "Complete your first session",    icon: "play.circle.fill"),
        Achievement(id: "sessions_10",  title: "Getting Warmed Up", description: "Complete 10 sessions",       icon: "bolt.fill"),
        Achievement(id: "sessions_50",  title: "Committed",     description: "Complete 50 sessions",           icon: "star.fill"),
        Achievement(id: "sessions_100", title: "Century Club",  description: "Complete 100 sessions",          icon: "trophy.fill"),
        // Hours
        Achievement(id: "hours_1",   title: "In the Zone",     description: "Study for 1 total hour",    icon: "clock"),
        Achievement(id: "hours_10",  title: "Ten Hours Deep",  description: "Study for 10 total hours",  icon: "clock.fill"),
        Achievement(id: "hours_50",  title: "Fifty Strong",    description: "Study for 50 total hours",  icon: "hourglass"),
        Achievement(id: "hours_100", title: "The Centurion",   description: "Study for 100 total hours", icon: "hourglass.bottomhalf.filled"),
        // Special
        Achievement(id: "perfect_score",     title: "Flawless",      description: "Achieve a 100% focus score",          icon: "checkmark.seal.fill"),
        Achievement(id: "consistency_week",  title: "Iron Habit",    description: "Study every day for 7 days straight",  icon: "repeat.circle.fill"),
    ]
}

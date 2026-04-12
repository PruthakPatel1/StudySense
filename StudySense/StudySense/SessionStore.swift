//
//  SessionStore.swift
//  StudySense
//
//  Created by Pruthak Patel on 4/11/26.
//

import Foundation
import Combine
internal import SwiftUI

struct StudySession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let name: String
    let elapsedTime: TimeInterval
    let focusedTime: TimeInterval
    let potentialDistractionTime: TimeInterval
    let distractionTime: TimeInterval
    let distractionCount: Int
    let focusScore: Int

    // Derived helpers used in the UI
    var formattedDuration: String {
        let t = Int(elapsedTime)
        let h = t / 3600
        let m = (t % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var formattedDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }
}

@MainActor
final class SessionStore: ObservableObject {
    

    @Published private(set) var sessions: [StudySession] = []

    private let key = "studysense.sessions"

    init() {
        load()
    }

    func save(_ session: StudySession) {
        sessions.insert(session, at: 0)   // newest first
        persist()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persist()
    }

    // MARK: - Computed analytics

    var totalSessions: Int { sessions.count }

    var averageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.map(\.focusScore).reduce(0, +) / sessions.count
    }

    /// Current daily streak (consecutive calendar days with ≥1 session)
    var streak: Int {
        guard !sessions.isEmpty else { return 0 }
        let cal = Calendar.current
        var streak = 0
        var checking = Date()
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) })
        while days.contains(cal.startOfDay(for: checking)) {
            streak += 1
            checking = cal.date(byAdding: .day, value: -1, to: checking)!
        }
        return streak
    }

    /// 15-week heatmap: returns a 2D array [week][weekday] with focus score bucket 0-4
    var heatmapData: [[Int]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // bucket score: 0=none, 1-4 by score quartile
        func bucket(_ score: Int) -> Int {
            if score == 0  { return 0 }
            if score < 50  { return 1 }
            if score < 70  { return 2 }
            if score < 85  { return 3 }
            return 4
        }
        // Group sessions by day
        var byDay: [Date: [StudySession]] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.date)
            byDay[day, default: []].append(s)
        }
        // Build 15 weeks × 7 days grid, ending today
        let totalDays = 15 * 7
        return (0..<15).map { week in
            (0..<7).map { day in
                let offset = -(totalDays - 1) + week * 7 + day
                guard let date = cal.date(byAdding: .day, value: offset, to: today) else { return 0 }
                guard let daySessions = byDay[date], !daySessions.isEmpty else { return 0 }
                let avg = daySessions.map(\.focusScore).reduce(0, +) / daySessions.count
                return bucket(avg)
            }
        }
    }
    var totalStudyHours: Double {
        sessions.reduce(0) { $0 + $1.elapsedTime } / 3600
    }

    var totalStudyTimeFormatted: String {
        let totalSeconds = Int(sessions.reduce(0) { $0 + $1.elapsedTime })
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var lifetimeAverageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.map(\.focusScore).reduce(0, +) / sessions.count
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([StudySession].self, from: data)
        else { return }
        sessions = decoded
    }
}

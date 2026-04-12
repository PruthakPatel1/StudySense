//
//  ProfileView.swift
//  StudySense
//
//  Created by Pruthak Patel on 4/12/26.

internal import SwiftUI

struct ProfileView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var achievements: AchievementStore

    @State private var showGoalPicker = false
    @State private var customGoalInput: String = ""

    let presetGoals: [Double] = [5, 10, 15, 20]

    private var weeklyHours: Double {
        achievements.weeklyStudyHours(from: store)
    }

    private var weeklyProgress: Double {
        min(1.0, weeklyHours / achievements.weeklyGoalHours)
    }

    private var unlockedAchievements: [Achievement] {
        achievements.achievements.filter(\.isUnlocked)
    }

    private var lockedAchievements: [Achievement] {
        achievements.achievements.filter { !$0.isUnlocked }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                Text("Profile")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 4)
                Text("Your lifetime focus stats")
                    .font(.system(size: 14))
                    .foregroundColor(.textMuted)
                    .padding(.bottom, 24)

                // Lifetime Stats
                Text("Lifetime Stats")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 12)

                HStack(spacing: 12) {
                    LifetimeStatCard(
                        icon: "clock.fill",
                        label: "Total Time",
                        value: store.totalStudyTimeFormatted,
                        color: .brandSecondary
                    )
                    LifetimeStatCard(
                        icon: "list.bullet.clipboard",
                        label: "Sessions",
                        value: "\(store.totalSessions)",
                        color: .brandPrimary
                    )
                    LifetimeStatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Avg Score",
                        value: store.sessions.isEmpty ? "--" : "\(store.lifetimeAverageScore)%",
                        color: .brandWarning
                    )
                }
                .padding(.bottom, 24)

                // Weekly Goal Ring
                Text("Weekly Goal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 12)

                HStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.surfaceMid, lineWidth: 10)
                            .frame(width: 110, height: 110)
                        Circle()
                            .trim(from: 0, to: weeklyProgress)
                            .stroke(
                                weeklyProgress >= 1 ? Color.brandSecondary : Color.brandPrimary,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 110, height: 110)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: weeklyProgress)
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", weeklyHours))
                                .font(.system(size: 22, weight: .semibold))
                                .monospacedDigit()
                                .foregroundColor(.textMain)
                            Text("/ \(Int(achievements.weeklyGoalHours))h")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(weeklyProgress >= 1 ? "🎉 Goal reached!" : "Keep going!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(weeklyProgress >= 1 ? .brandSecondary : .textMain)

                        Text("\(String(format: "%.1f", max(0, achievements.weeklyGoalHours - weeklyHours)))h remaining this week")
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)

                        Button {
                            showGoalPicker = true
                        } label: {
                            Text("Change Goal")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textInverse)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.brandPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 24)

                // Achievements — Unlocked
                if !unlockedAchievements.isEmpty {
                    Text("Achievements · \(unlockedAchievements.count)/\(achievements.achievements.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textMain)
                        .padding(.bottom, 12)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(unlockedAchievements) { achievement in
                            AchievementCard(achievement: achievement, unlocked: true)
                        }
                    }
                    .padding(.bottom, 16)
                }

                // Achievements — Locked
                if !lockedAchievements.isEmpty {
                    Text(unlockedAchievements.isEmpty ? "Achievements" : "Locked")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textMuted)
                        .padding(.bottom, 12)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(lockedAchievements) { achievement in
                            AchievementCard(achievement: achievement, unlocked: false)
                        }
                    }
                    .padding(.bottom, 110)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
        .sheet(isPresented: $showGoalPicker) {
            GoalPickerSheet(
                currentGoal: achievements.weeklyGoalHours,
                presets: presetGoals,
                customInput: $customGoalInput
            ) { newGoal in
                achievements.weeklyGoalHours = newGoal
                showGoalPicker = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Supporting Views

struct LifetimeStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textMuted)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(.textMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.bgSurface)
        .cornerRadius(20)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.system(size: 22))
                .foregroundColor(unlocked ? .brandPrimary : .textMuted.opacity(0.3))
                .frame(width: 44, height: 44)
                .background(unlocked ? Color.brandPrimary.opacity(0.15) : Color.surfaceMid)
                .cornerRadius(12)

            Text(achievement.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(unlocked ? .textMain : .textMuted.opacity(0.5))

            Text(achievement.description)
                .font(.system(size: 11))
                .foregroundColor(.textMuted.opacity(unlocked ? 0.8 : 0.4))
                .lineLimit(2)

            if let date = achievement.unlockedAt {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundColor(.brandPrimary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.bgSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(unlocked ? Color.brandPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct GoalPickerSheet: View {
    let currentGoal: Double
    let presets: [Double]
    @Binding var customInput: String
    let onSelect: (Double) -> Void

    @State private var selected: Double
    @FocusState private var customFocused: Bool

    init(currentGoal: Double, presets: [Double], customInput: Binding<String>, onSelect: @escaping (Double) -> Void) {
        self.currentGoal = currentGoal
        self.presets = presets
        self._customInput = customInput
        self.onSelect = onSelect
        self._selected = State(initialValue: currentGoal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Weekly Study Goal")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textMain)
                .padding(.top, 24)

            Text("Presets")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textMuted)

            HStack(spacing: 12) {
                ForEach(presets, id: \.self) { preset in
                    Button("\(Int(preset))h") {
                        selected = preset
                        customInput = ""
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(selected == preset && customInput.isEmpty ? .textInverse : .textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selected == preset && customInput.isEmpty ? Color.brandPrimary : Color.bgSurface)
                    .cornerRadius(16)
                }
            }

            Text("Custom")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textMuted)

            HStack {
                TextField("Enter hours", text: $customInput)
                    .keyboardType(.numberPad)
                    .focused($customFocused)
                    .font(.system(size: 15))
                    .foregroundColor(.textMain)
                    .padding(14)
                    .background(Color.bgSurface)
                    .cornerRadius(16)

                Text("hrs / week")
                    .font(.system(size: 14))
                    .foregroundColor(.textMuted)
            }

            Button {
                if let custom = Double(customInput), custom > 0 {
                    onSelect(custom)
                } else {
                    onSelect(selected)
                }
            } label: {
                Text("Set Goal")
            }
            .primaryButton()

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.bgCanvas.ignoresSafeArea())
    }
}

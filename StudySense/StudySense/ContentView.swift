//
//  ContentView.swift
//  StudySense
//
//  Created by Pruthak Patel on 2/26/26.
//

import SwiftUI

// MARK: - Root

struct ContentView: View {

    @StateObject private var recorder = SessionRecorder()
    @State private var appView: AppView = .home
    @State private var navTab: NavTab   = .timer

    enum AppView { case home, activeSession, postSession }
    enum NavTab: CaseIterable {
        case timer, analytics, settings
        var label: String {
            switch self { case .timer: "Timer"; case .analytics: "Analytics"; case .settings: "Settings" }
        }
        var icon: String {
            switch self { case .timer: "timer"; case .analytics: "chart.bar"; case .settings: "gearshape" }
        }
    }

    var body: some View {
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            if appView == .activeSession {
                ActiveSessionView(recorder: recorder, appView: $appView)
                    .transition(.opacity)
            } else {
                ZStack(alignment: .bottom) {
                    mainContent
                        .animation(.easeInOut(duration: 0.25), value: appView)
                        .animation(.easeInOut(duration: 0.25), value: navTab)

                    BottomNavView(activeTab: navTab) { tab in
                        if appView == .postSession { appView = .home }
                        navTab = tab
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: appView)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch appView {
        case .postSession:
            PostSessionView(recorder: recorder, appView: $appView, navTab: $navTab)
        default:
            switch navTab {
            case .timer:     HomeView(recorder: recorder, appView: $appView)
            case .analytics: AnalyticsView()
            case .settings:  SettingsView()
            }
        }
    }
}

// MARK: - Bottom Nav

struct BottomNavView: View {
    let activeTab: ContentView.NavTab
    let onTabChange: (ContentView.NavTab) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ContentView.NavTab.allCases, id: \.self) { tab in
                let isActive = activeTab == tab
                Button { onTabChange(tab) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .regular))
                        if isActive {
                            Text(tab.label)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isActive ? .textInverse : .textMuted)
                    .padding(.vertical, 10)
                    .padding(.horizontal, isActive ? 20 : 14)
                    .background(isActive ? Color.brandPrimary : Color.clear)
                    .clipShape(Capsule())
                }
                .animation(.easeInOut(duration: 0.2), value: activeTab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.bgSurface)
        .clipShape(Capsule())
    }
}

// MARK: - VIEW 1: HOME

struct HomeView: View {
    @ObservedObject var recorder: SessionRecorder
    @Binding var appView: ContentView.AppView

    enum HomeMode { case stopwatch, timer }
    @State private var mode: HomeMode = .stopwatch
    @State private var timerMinutes = 25
    @State private var timerSeconds = 0

    var subtitle: String {
        mode == .stopwatch ? "Place your phone face down to begin" : "Set your focus duration"
    }

    var body: some View {
        VStack(spacing: 0) {

            // Mode Toggle — fixed at top so the time display never shifts
            HStack(spacing: 0) {
                ForEach([HomeMode.stopwatch, .timer], id: \.self) { m in
                    let isActive = mode == m
                    Button(m == .stopwatch ? "Stopwatch" : "Timer") {
                        withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                        timerMinutes = m == .timer ? 25 : 0
                        timerSeconds = 0
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isActive ? .textInverse : .textMuted)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(isActive ? Color.brandPrimary : Color.clear)
                    .clipShape(Capsule())
                }
            }
            .padding(4)
            .background(Color.bgSurface)
            .clipShape(Capsule())
            .padding(.top, 64)

            Spacer()

            // Time Display
            if mode == .stopwatch {
                Text(recorder.formattedTime)
                    .font(.system(size: 96, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(.textMain)
                    .tracking(-2)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    // Minutes
                    VStack(spacing: 8) {
                        Button { timerMinutes = min(99, timerMinutes + 1) } label: {
                            Image(systemName: "chevron.up").foregroundColor(.textMuted)
                        }
                        Text(String(format: "%02d", timerMinutes))
                            .font(.system(size: 96, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(.textMain)
                        Button { timerMinutes = max(0, timerMinutes - 1) } label: {
                            Image(systemName: "chevron.down").foregroundColor(.textMuted)
                        }
                    }
                    Text(":")
                        .font(.system(size: 96, weight: .semibold))
                        .foregroundColor(.textMuted)
                    // Seconds
                    VStack(spacing: 8) {
                        Button { timerSeconds = timerSeconds >= 55 ? 0 : timerSeconds + 5 } label: {
                            Image(systemName: "chevron.up").foregroundColor(.textMuted)
                        }
                        Text(String(format: "%02d", timerSeconds))
                            .font(.system(size: 96, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(.textMain)
                        Button { timerSeconds = timerSeconds <= 0 ? 55 : timerSeconds - 5 } label: {
                            Image(systemName: "chevron.down").foregroundColor(.textMuted)
                        }
                    }
                }
            }

            Text(subtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textMuted)
                .padding(.top, 24)

            Spacer()

            Button {
                recorder.start()
                appView = .activeSession
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill").font(.system(size: 16))
                    Text("Start Focus")
                }
            }
            .primaryButton()
            .padding(.horizontal, 24)
            .padding(.bottom, 110)
        }
        .padding(.top, 64)
    }
}

// MARK: - VIEW 2: ACTIVE SESSION

struct ActiveSessionView: View {
    @ObservedObject var recorder: SessionRecorder
    @Binding var appView: ContentView.AppView

    @State private var breathing = false

    var body: some View {
        ZStack {
            Color.sessionBg.ignoresSafeArea()

            VStack {
                // Elapsed time — subtle header
                VStack(spacing: 4) {
                    Text("SESSION ACTIVE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textDim)
                        .tracking(4)
                    Text(recorder.formattedTime)
                        .font(.system(size: 24, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.textDim)
                }
                .padding(.top, 64)

                Spacer()

                // Center — phone icon + status
                VStack(spacing: 24) {
                    Image(systemName: "iphone")
                        .font(.system(size: 48))
                        .foregroundColor(recorder.motion.isDistracted ? .brandWarning : .textDim)
                        .rotationEffect(.degrees(180))
                        .opacity(breathing ? 0.4 : 0.2)
                        .scaleEffect(breathing ? 1.1 : 1.0)

                    Text(recorder.motion.isDistracted ? "Distracted!" : "Phone face down to focus.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(recorder.motion.isDistracted ? .brandWarning : .textDim)
                        .animation(.easeInOut(duration: 0.3), value: recorder.motion.isDistracted)
                }

                Spacer()

                // Pause + Stop buttons
                HStack(spacing: 12) {
                    // Pause / Resume
                    Button {
                        recorder.isPaused ? recorder.resume() : recorder.pause()
                    } label: {
                        Image(systemName: recorder.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textMuted)
                            .frame(width: 44, height: 44)
                            .background(Color.clear)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.surfaceMid, lineWidth: 1))
                    }

                    // Stop Session
                    Button {
                        if !recorder.isPaused { recorder.pause() }
                        appView = .postSession
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill").font(.system(size: 11))
                            Text("Stop Session")
                        }
                    }
                    .outlineButton()
                }
                .padding(.bottom, 64)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}

// MARK: - VIEW 3: POST-SESSION SUMMARY

struct PostSessionView: View {
    @ObservedObject var recorder: SessionRecorder
    @Binding var appView: ContentView.AppView
    @Binding var navTab: ContentView.NavTab

    @State private var title: String = PostSessionView.makeTitle()
    @State private var isEditing = false

    static func makeTitle() -> String {
        let hour    = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        let days    = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        let period: String
        if      hour >= 5  && hour < 12 { period = "Morning" }
        else if hour >= 12 && hour < 17 { period = "Afternoon" }
        else if hour >= 17 && hour < 21 { period = "Evening" }
        else                            { period = "Night" }
        return "\(days[weekday - 1]) \(period) Focus"
    }

    var focusScore: Int {
        guard recorder.elapsedTime > 0 else { return 0 }
        let focused = max(0, recorder.elapsedTime - recorder.totalDistractionTime)
        return Int((focused / recorder.elapsedTime) * 100)
    }

    var focusPercent: CGFloat {
        guard recorder.elapsedTime > 0 else { return 1 }
        return CGFloat(max(0, recorder.elapsedTime - recorder.totalDistractionTime) / recorder.elapsedTime)
    }

    var distractedPercent: CGFloat {
        guard recorder.elapsedTime > 0 else { return 0 }
        return CGFloat(min(1, recorder.totalDistractionTime / recorder.elapsedTime))
    }

    var formattedDistractionTime: String {
        let t = Int(recorder.totalDistractionTime)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Editable title
                HStack(spacing: 8) {
                    if isEditing {
                        TextField("Session title", text: $title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.textMain)
                            .tint(.brandPrimary)
                            .onSubmit { isEditing = false }
                        Button { isEditing = false } label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(.brandPrimary)
                        }
                    } else {
                        Text(title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.textMain)
                        Button { isEditing = true } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(.textMuted)
                        }
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 32)

                // Hero Score Card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Focus Score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textInverse.opacity(0.6))
                        .padding(.bottom, 4)

                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(focusScore)")
                            .font(.system(size: 72, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(.textInverse)
                        Text("%")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.textInverse.opacity(0.6))
                            .padding(.bottom, 8)
                    }
                    .padding(.bottom, 24)

                    // Focus / Distracted bar
                    GeometryReader { geo in
                        let gap: CGFloat = distractedPercent > 0 ? 2 : 0
                        let available = geo.size.width - gap
                        HStack(spacing: gap) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "22C55E"))
                                .frame(width: available * focusPercent)
                            if distractedPercent > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.brandWarning)
                                    .frame(width: available * distractedPercent)
                            }
                        }
                    }
                    .frame(height: 12)
                    .padding(.bottom, 16)

                    // Legend
                    HStack(spacing: 16) {
                        LegendDot(color: Color(hex: "22C55E"), label: "Focus \(Int(focusPercent * 100))%")
                        LegendDot(color: Color.brandWarning, label: "Distracted \(Int(distractedPercent * 100))%")
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.brandPrimary)
                .cornerRadius(32)
                .padding(.bottom, 16)

                // Stats grid — Total Time + Distractions
                HStack(spacing: 12) {
                    StatCard(icon: "clock", label: "Total Time",   value: recorder.formattedTime)
                    StatCard(icon: "exclamationmark.triangle", label: "Distractions", value: "\(recorder.distractionCount)")
                }
                .padding(.bottom, 12)

                // Distracted Time (backend addition)
                StatCard(icon: "timer", label: "Distracted Time", value: formattedDistractionTime, valueColor: .brandWarning)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 32)

                // Done
                Button {
                    recorder.stop()
                    navTab  = .timer
                    appView = .home
                } label: {
                    Text("Done")
                }
                .primaryButton()
                .padding(.bottom, 110)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - VIEW 4: ANALYTICS

struct AnalyticsView: View {

    // Placeholder heatmap — static so it doesn't regenerate on re-renders
    static let heatmapData: [[Int]] = {
        (0..<15).map { _ in
            (0..<7).map { _ -> Int in
                let r = Double.random(in: 0..<1)
                if r < 0.30 { return 0 }
                if r < 0.55 { return 1 }
                if r < 0.75 { return 2 }
                if r < 0.90 { return 3 }
                return 4
            }
        }
    }()

    static let recentSessions: [(date: String, name: String, score: Int, duration: String)] = [
        ("Today",      "Friday Afternoon Focus",     92, "45m"),
        ("Yesterday",  "Thursday Night Study",        78, "60m"),
        ("Feb 12",     "Wednesday Morning Flow",      85, "30m"),
        ("Feb 11",     "Tuesday Evening Focus",       64, "25m"),
        ("Feb 10",     "Monday Afternoon Push",       91, "50m"),
    ]

    let heatmapColors: [Color] = [
        .bgSurface,
        Color(hex: "1A3A1A"),
        Color(hex: "2A5A2A"),
        Color(hex: "4A9A4A"),
        .brandSecondary,
    ]

    func scoreColor(_ score: Int) -> Color {
        if score >= 85 { return .brandSecondary }
        if score >= 70 { return .brandPrimary }
        return .brandWarning
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                Text("Analytics")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 4)
                Text("Your focus journey at a glance")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.textMuted)
                    .padding(.bottom, 24)

                // Quick stats row
                HStack(spacing: 12) {
                    MiniStatCard(icon: "flame", iconColor: .brandWarning, label: "Streak", value: "5 days")
                    MiniStatCard(icon: "chart.line.uptrend.xyaxis", iconColor: .brandSecondary, label: "Avg Score", value: "82%")
                    MiniStatCard(icon: nil, iconColor: .clear, label: "Sessions", value: "47")
                }
                .padding(.bottom, 24)

                // Heatmap card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Focus Activity")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textMain)
                        .padding(.bottom, 4)
                    Text("Last 15 weeks")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textMuted)
                        .padding(.bottom, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 3) {
                            ForEach(0..<AnalyticsView.heatmapData.count, id: \.self) { w in
                                VStack(spacing: 3) {
                                    ForEach(0..<AnalyticsView.heatmapData[w].count, id: \.self) { d in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(heatmapColors[AnalyticsView.heatmapData[w][d]])
                                            .frame(width: 18, height: 18)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 12)

                    // Legend
                    HStack(spacing: 8) {
                        Text("Less").font(.system(size: 12)).foregroundColor(.textMuted)
                        ForEach(0..<5) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(heatmapColors[i])
                                .frame(width: 12, height: 12)
                        }
                        Text("More").font(.system(size: 12)).foregroundColor(.textMuted)
                    }
                }
                .padding(20)
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 24)

                // Recent Sessions
                Text("Recent Sessions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 12)

                VStack(spacing: 12) {
                    ForEach(AnalyticsView.recentSessions, id: \.name) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.date)
                                    .font(.system(size: 12)).foregroundColor(.textMuted)
                                Text(session.name)
                                    .font(.system(size: 14, weight: .medium)).foregroundColor(.textMain)
                                Text(session.duration)
                                    .font(.system(size: 12)).foregroundColor(.textMuted)
                            }
                            Spacer()
                            Text("\(session.score)%")
                                .font(.system(size: 24, weight: .semibold))
                                .monospacedDigit()
                                .foregroundColor(scoreColor(session.score))
                        }
                        .padding(20)
                        .background(Color.bgSurface)
                        .cornerRadius(32)
                    }
                }
                .padding(.bottom, 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }
}

// MARK: - VIEW 5: SETTINGS

struct SettingsView: View {
    @State private var notifications = true
    @State private var haptics       = true
    @State private var dnd           = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 4)
                Text("Customize your focus experience")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.textMuted)
                    .padding(.bottom, 24)

                // General
                VStack(spacing: 0) {
                    SettingToggleRow(icon: "bell",  label: "Notifications",  description: "Session reminders",       isOn: $notifications)
                    Divider().background(Color.surfaceMid).padding(.horizontal, 20)
                    SettingToggleRow(icon: "iphone.radiowaves.left.and.right", label: "Haptic Feedback", description: "Vibrations on interactions", isOn: $haptics)
                    Divider().background(Color.surfaceMid).padding(.horizontal, 20)
                    SettingToggleRow(icon: "moon",  label: "Do Not Disturb", description: "Silence during sessions", isOn: $dnd)
                }
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 16)

                // More
                VStack(spacing: 0) {
                    SettingLinkRow(icon: "shield",       label: "Privacy", description: "Data & permissions")
                    Divider().background(Color.surfaceMid).padding(.horizontal, 20)
                    SettingLinkRow(icon: "info.circle",  label: "About",   description: "Version 1.0.0")
                }
                .background(Color.bgSurface)
                .cornerRadius(32)

                Text("StudySense v1.0.0")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 32)
                    .padding(.bottom, 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .textMain

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.textMuted)
                .frame(width: 40, height: 40)
                .background(Color.surfaceMid)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textMuted)
                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(valueColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct MiniStatCard: View {
    let icon: String?
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let icon {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
            } else {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textMuted)
            }
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(.textMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.bgSurface)
        .cornerRadius(16)
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textInverse.opacity(0.7))
        }
    }
}

struct SettingToggleRow: View {
    let icon: String
    let label: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.textMuted)
                .frame(width: 36, height: 36)
                .background(Color.surfaceMid)
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)       .font(.system(size: 14, weight: .medium)).foregroundColor(.textMain)
                Text(description) .font(.system(size: 12)).foregroundColor(.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn).toggleStyle(NeonToggleStyle())
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

struct SettingLinkRow: View {
    let icon: String
    let label: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.textMuted)
                .frame(width: 36, height: 36)
                .background(Color.surfaceMid)
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)       .font(.system(size: 14, weight: .medium)).foregroundColor(.textMain)
                Text(description) .font(.system(size: 12)).foregroundColor(.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textMuted)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

//
//  ContentView.swift
//  StudySense
//
//  Created by Pruthak Patel on 2/26/26.
//

internal import SwiftUI
import AudioToolbox
import AVFoundation
import CoreMotion

// MARK: - Root

struct ContentView: View {

    @StateObject private var recorder = SessionRecorder()
    @StateObject private var store = SessionStore()
    @StateObject private var achievements = AchievementStore()
    @State private var appView: AppView = .home
    @State private var navTab: NavTab   = .timer

    enum AppView { case home, activeSession, postSession }
    enum NavTab: CaseIterable {
        case timer, analytics, profile, settings
        var label: String {
            switch self {
            case .timer: "Timer"
            case .analytics: "Analytics"
            case .profile: "Profile"
            case .settings: "Settings"
            }
        }
        var icon: String {
            switch self {
            case .timer: "timer"
            case .analytics: "chart.bar"
            case .profile: "person.crop.circle"
            case .settings: "gearshape"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            if appView == .activeSession {
                if recorder.isPomodoroMode {
                    PomodoroSessionView(recorder: recorder, appView: $appView)
                        .transition(.opacity)
                } else {
                    ActiveSessionView(recorder: recorder, appView: $appView)
                        .transition(.opacity)
                }
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
        .overlay(alignment: .top) {
            if let first = achievements.newlyUnlocked.first {
                AchievementToast(achievement: first)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { achievements.newlyUnlocked = [] }
                        }
                    }
                    .animation(.spring(), value: achievements.newlyUnlocked.isEmpty)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: appView)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch appView {
        case .postSession:
            PostSessionView(recorder: recorder, appView: $appView, navTab: $navTab, store: store, achievements: achievements)
        default:
            switch navTab {
            case .timer:     HomeView(recorder: recorder, appView: $appView)
            case .analytics: AnalyticsView(store: store)
            case .profile:   ProfileView(store: store, achievements: achievements)
            case .settings: SettingsView(store: store, achievements: achievements)
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

    enum HomeMode { case stopwatch, timer, pomodoro }
    @State private var mode: HomeMode = .stopwatch
    @State private var timerMinutes = 25
    @State private var pomodoroStudyMinutes = 25
    @State private var pomodoroBreakMinutes = 5

    var subtitle: String {
        switch mode {
        case .stopwatch: return "Press start and place your phone face down to begin"
        case .timer:     return "Set your focus duration, press start, and place your phone face down"
        case .pomodoro:  return "Set study and break durations, press start, and place your phone face down"
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Mode Toggle
            HStack(spacing: 0) {
                ForEach([HomeMode.stopwatch, .timer, .pomodoro], id: \.self) { m in
                    let isActive = mode == m
                    let label: String = {
                        switch m {
                        case .stopwatch: return "Stopwatch"
                        case .timer:     return "Timer"
                        case .pomodoro:  return "Pomodoro"
                        }
                    }()
                    Button(label) {
                        withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isActive ? .textInverse : .textMuted)
                    .padding(.vertical, 8)
                    .padding(.horizontal, isActive ? 16 : 14)
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
            } else if mode == .timer {
                TimerConfigView(minutes: $timerMinutes)
            } else {
                // Pomodoro config
                PomodoroConfigView(studyMinutes: $pomodoroStudyMinutes, breakMinutes: $pomodoroBreakMinutes)
            }

            Text(subtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                if mode == .pomodoro {
                    recorder.startPomodoro(studyMinutes: pomodoroStudyMinutes, breakMinutes: pomodoroBreakMinutes)
                } else {
                    let duration = mode == .timer
                        ? TimeInterval(timerMinutes * 60)
                        : 0
                    recorder.start(timerDuration: duration)
                }
                appView = .activeSession
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill").font(.system(size: 16))
                    Text(mode == .pomodoro ? "Start Pomodoro" : "Start Focus")
                }
            }
            .primaryButton()
            .disabled(mode == .timer && timerMinutes == 0)
            .opacity(mode == .timer && timerMinutes == 0 ? 0.4 : 1.0)
            .padding(.horizontal, 24)
            .padding(.bottom, 110)
        }
        .padding(.top, 64)
    }
}

// MARK: - Timer Config View

struct TimerConfigView: View {
    @Binding var minutes: Int

    let presets = [15, 25, 30, 45, 60, 90]

    var body: some View {
        VStack(spacing: 28) {
            // Preset chips
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.brandPrimary)
                        .font(.system(size: 14))
                    Text("Focus Duration")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                // Two rows of 3
                let rows = presets.chunked(into: 3)
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 8) {
                        ForEach(rows[rowIndex], id: \.self) { preset in
                            let selected = minutes == preset
                            Button("\(preset)m") {
                                minutes = preset
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selected ? .textInverse : .textMuted)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selected ? Color.brandPrimary : Color.bgSurface)
                            .cornerRadius(14)
                        }
                    }
                }
            }

            Rectangle()
                .fill(Color.surfaceMid)
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Stepper
            HStack(spacing: 24) {
                Button { minutes = max(1, minutes - 5) } label: {
                    Image(systemName: "minus")
                        .foregroundColor(.textMuted)
                        .frame(width: 44, height: 44)
                        .background(Color.bgSurface)
                        .clipShape(Circle())
                }
                Text("\(minutes) min")
                    .font(.system(size: 40, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(.textMain)
                    .frame(minWidth: 130)
                Button { minutes = min(180, minutes + 5) } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.textMuted)
                        .frame(width: 44, height: 44)
                        .background(Color.bgSurface)
                        .clipShape(Circle())
                }
            }
        }
        .padding(24)
        .background(Color.bgSurface)
        .cornerRadius(32)
        .padding(.horizontal, 24)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Pomodoro Config View

struct PomodoroConfigView: View {
    @Binding var studyMinutes: Int
    @Binding var breakMinutes: Int

    let studyPresets  = [15, 25, 30, 45, 50]
    let breakPresets  = [5, 10, 15]

    var body: some View {
        VStack(spacing: 28) {
            // Study duration
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.brandPrimary)
                        .font(.system(size: 14))
                    Text("Study Duration")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                HStack(spacing: 8) {
                    ForEach(studyPresets, id: \.self) { preset in
                        let selected = studyMinutes == preset
                        Button("\(preset)m") {
                            studyMinutes = preset
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selected ? .textInverse : .textMuted)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selected ? Color.brandPrimary : Color.bgSurface)
                        .cornerRadius(14)
                    }
                }
                // Custom stepper
                HStack(spacing: 16) {
                    Button { studyMinutes = max(5, studyMinutes - 5) } label: {
                        Image(systemName: "minus")
                            .foregroundColor(.textMuted)
                            .frame(width: 36, height: 36)
                            .background(Color.bgSurface)
                            .clipShape(Circle())
                    }
                    Text("\(studyMinutes) min")
                        .font(.system(size: 32, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.textMain)
                        .frame(minWidth: 110)
                    Button { studyMinutes = min(120, studyMinutes + 5) } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.textMuted)
                            .frame(width: 36, height: 36)
                            .background(Color.bgSurface)
                            .clipShape(Circle())
                    }
                }
            }

            // Divider
            Rectangle()
                .fill(Color.surfaceMid)
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Break duration
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "cup.and.saucer")
                        .foregroundColor(.brandSecondary)
                        .font(.system(size: 14))
                    Text("Break Duration")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                HStack(spacing: 8) {
                    ForEach(breakPresets, id: \.self) { preset in
                        let selected = breakMinutes == preset
                        Button("\(preset)m") {
                            breakMinutes = preset
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selected ? .textInverse : .textMuted)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selected ? Color.brandSecondary : Color.bgSurface)
                        .cornerRadius(14)
                    }
                }
                HStack(spacing: 16) {
                    Button { breakMinutes = max(1, breakMinutes - 1) } label: {
                        Image(systemName: "minus")
                            .foregroundColor(.textMuted)
                            .frame(width: 36, height: 36)
                            .background(Color.bgSurface)
                            .clipShape(Circle())
                    }
                    Text("\(breakMinutes) min")
                        .font(.system(size: 32, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.textMain)
                        .frame(minWidth: 110)
                    Button { breakMinutes = min(60, breakMinutes + 1) } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.textMuted)
                            .frame(width: 36, height: 36)
                            .background(Color.bgSurface)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(24)
        .background(Color.bgSurface)
        .cornerRadius(32)
        .padding(.horizontal, 24)
    }
}

// MARK: - VIEW 2: ACTIVE SESSION (POMODORO)

struct PomodoroSessionView: View {
    @ObservedObject var recorder: SessionRecorder
    @Binding var appView: ContentView.AppView
    @AppStorage("settings.haptics") private var hapticsEnabled = true

    @State private var pulse = false

    private var isBreak: Bool { recorder.pomodoroPhase == .breakTime }
    private var phaseColor: Color { isBreak ? .brandSecondary : .brandPrimary }
    private var phaseLabel: String { isBreak ? "BREAK TIME" : "STUDY TIME" }

    var body: some View {
        ZStack {
            // Background shifts subtly between study/break
            (isBreak ? Color(hex: "080F0D") : Color.sessionBg)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: isBreak)

            VStack(spacing: 0) {

                // Top label
                VStack(spacing: 4) {
                    Text(phaseLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(phaseColor.opacity(0.7))
                        .tracking(4)
                        .animation(.easeInOut(duration: 0.3), value: isBreak)

                    Text("Round \(recorder.pomodoroRound)")
                        .font(.system(size: 12))
                        .foregroundColor(.textDim)
                }
                .padding(.top, 64)

                Spacer()

                // Countdown ring
                ZStack {
                    Circle()
                        .stroke(Color.surfaceMid, lineWidth: 8)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: CGFloat(1 - recorder.pomodoroPhaseProgress))
                        .stroke(phaseColor,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: recorder.pomodoroPhaseProgress)

                    VStack(spacing: 6) {
                        Text(recorder.formattedPomodoroPhaseRemaining)
                            .font(.system(size: 48, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(.textMain)
                        Text(isBreak ? "Break remaining" : "Study remaining")
                            .font(.system(size: 12))
                            .foregroundColor(.textDim)
                    }
                }
                .scaleEffect(pulse ? 1.03 : 1.0)

                // Total study banked
                Text("Total studied: \(formattedStudyTime)")
                    .font(.system(size: 13))
                    .foregroundColor(.textDim)
                    .padding(.top, 20)

                Spacer()

                // Status indicator (only during study phase)
                if !isBreak {
                    VStack(spacing: 8) {
                        Image(systemName: "iphone")
                            .font(.system(size: 32))
                            .foregroundColor(statusColor)
                            .rotationEffect(.degrees(180))
                            .opacity(pulse ? 0.4 : 0.2)
                            .scaleEffect(pulse ? 1.1 : 1.0)
                        Text(recorder.isPaused ? "Paused" : statusText)
                            .font(.system(size: 14))
                            .foregroundColor(statusColor)
                    }
                    .padding(.bottom, 8)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.brandSecondary)
                        Text("Sensors paused during break")
                            .font(.system(size: 13))
                            .foregroundColor(.textDim)
                    }
                    .padding(.bottom, 8)
                }

                // Controls
                HStack(spacing: 12) {
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

                    Button {
                        recorder.finishSession()
                        appView = .postSession
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill").font(.system(size: 11))
                            Text("End Pomodoro")
                        }
                    }
                    .outlineButton()
                }
                .padding(.bottom, 64)
            }
        }
        .onChange(of: recorder.pomodoroPhaseDidChange) { changed in
            guard changed else { return }
            if hapticsEnabled {
                AudioToolbox.AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    AudioToolbox.AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }
            withAnimation(.easeInOut(duration: 0.4)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { pulse = false }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var formattedStudyTime: String {
        let t = Int(recorder.pomodoroTotalStudyTime)
        let m = t / 60
        let s = t % 60
        if m >= 60 {
            return "\(m / 60)h \(m % 60)m"
        }
        return String(format: "%02d:%02d", m, s)
    }

    private var statusText: String {
        switch recorder.phoneState {
        case .focused:               return "Focused"
        case .potentiallyDistracted: return "Potential distraction"
        case .distracted:            return "Distracted"
        }
    }

    private var statusColor: Color {
        switch recorder.phoneState {
        case .focused:               return .brandSecondary
        case .potentiallyDistracted: return .brandWarning
        case .distracted:            return .brandWarning
        }
    }
}



struct ActiveSessionView: View {
    @ObservedObject var recorder: SessionRecorder
    @Binding var appView: ContentView.AppView
    @AppStorage("settings.haptics") private var hapticsEnabled = true

    @State private var breathing = false
    @State private var showTimerCompleteAlert = false

    var body: some View {
        ZStack {
            Color.sessionBg.ignoresSafeArea()

            VStack {
                // Elapsed time — subtle header
                VStack(spacing: 4) {
                    Text(recorder.isTimerMode ? "TIME REMAINING" : "SESSION ACTIVE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textDim)
                        .tracking(4)

                    if recorder.isTimerMode {
                        ZStack {
                            // Background track
                            Circle()
                                .stroke(Color.surfaceMid, lineWidth: 3)
                                .frame(width: 120, height: 120)
                            // Progress arc (drains clockwise)
                            Circle()
                                .trim(from: 0, to: CGFloat(1 - recorder.timerProgress))
                                .stroke(Color.brandPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: recorder.timerProgress)
                            // Countdown text inside ring
                            Text(recorder.formattedRemainingTime)
                                .font(.system(size: 32, weight: .semibold))
                                .monospacedDigit()
                                .foregroundColor(.textMain)
                        }
                        // Elapsed underneath in dim text
                        Text("Elapsed: \(recorder.formattedTime)")
                            .font(.system(size: 12))
                            .foregroundColor(.textDim)
                    } else {
                        Text(recorder.formattedTime)
                            .font(.system(size: 24, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(.textDim)
                    }
                }
                .padding(.top, 64)

                Spacer()

                // Center — phone icon + status
                VStack(spacing: 24) {
                    Image(systemName: "iphone")
                        .font(.system(size: 48))
                        .foregroundColor(statusColor)
                        .rotationEffect(.degrees(180))
                        .opacity(breathing ? 0.4 : 0.2)
                        .scaleEffect(breathing ? 1.1 : 1.0)

                    Text(statusText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(statusColor)
                        .animation(.easeInOut(duration: 0.3), value: recorder.phoneState)
                }
                
                var statusText: String {
                    if recorder.isPaused {
                        return "Session Paused"
                    }
                    
                    switch recorder.phoneState {
                    case .focused:
                        return "Focused"
                    case .potentiallyDistracted:
                        return "Potential distraction"
                    case .distracted:
                        return "Distracted"
                    }
                }

                var statusColor: Color {
                    if recorder.isPaused {
                        return .textDim
                    }
                    
                    switch recorder.phoneState {
                    case .focused:
                        return .brandSecondary
                    case .potentiallyDistracted:
                        return .brandWarning
                    case .distracted:
                        return .brandWarning
                    }
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
                        recorder.finishSession()
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
        .onChange(of: recorder.timerDidComplete) { completed in
            if completed {
                showTimerCompleteAlert = true
                // Vibrate
                if hapticsEnabled {
                    AudioToolbox.AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        AudioToolbox.AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    }
                }
            }
        }
        .alert("Time's Up!", isPresented: $showTimerCompleteAlert) {
            Button("End Session") {
                recorder.finishSession()
                appView = .postSession
            }
            Button("Keep Going") {
                recorder.resume()
                recorder.isTimerMode = false  // switch to stopwatch mode
            }
        } message: {
            Text("Your focus session is complete.")
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
    var store: SessionStore
    var achievements: AchievementStore

    @State private var title: String = ""
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

    private var rawFocused: Double {
        recorder.totalFocusedTime
    }

    private var rawPotential: Double {
        recorder.totalPotentialDistractionTime
    }

    private var rawDistracted: Double {
        recorder.totalDistractionTime
    }

    private var totalTracked: Double {
        let total = rawFocused + rawPotential + rawDistracted
        return total > 0 ? total : 1
    }

    var focusedPercent: CGFloat {
        CGFloat(rawFocused / totalTracked)
    }

    var potentialPercent: CGFloat {
        CGFloat(rawPotential / totalTracked)
    }

    var distractedPercent: CGFloat {
        CGFloat(rawDistracted / totalTracked)
    }
    
    private var focusedDisplayPercent: Int {
        Int((Double(focusedPercent) * 100).rounded())
    }

    private var potentialDisplayPercent: Int {
        Int((Double(potentialPercent) * 100).rounded())
    }

    private var distractedDisplayPercent: Int {
        max(0, 100 - focusedDisplayPercent - potentialDisplayPercent)
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
                        Text("\(recorder.focusScore)")
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
                        let segments = [
                            (color: Color(hex: "22C55E"), value: focusedPercent),     // green
                            (color: Color.orange, value: potentialPercent),           // orange
                            (color: Color.red, value: distractedPercent)              // red
                        ].filter { $0.value > 0 }
                        
                        let gap: CGFloat = segments.count > 1 ? 2 : 0
                        let totalGap = CGFloat(max(0, segments.count - 1)) * gap
                        let available = geo.size.width - totalGap
                        
                        HStack(spacing: gap) {
                            ForEach(0..<segments.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(segments[index].color)
                                    .frame(width: available * segments[index].value)
                            }
                        }
                    }
                    .frame(height: 12)
                    .padding(.bottom, 16)

                    // Legend
                    HStack(spacing: 16) {
                        LegendDot(color: Color(hex: "22C55E"), label: "Focused \(focusedDisplayPercent)%")
                        LegendDot(color: Color.orange, label: "Partial \(potentialDisplayPercent)%")
                        LegendDot(color: Color.red, label: "Distracted \(distractedDisplayPercent)%")
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
                VStack(spacing: 12) {
                    StatCard(
                        icon: "eye",
                        label: "Potentially Distracted",
                        value: recorder.formattedPotentialDistractionTime,
                        valueColor: .brandWarning
                    )
                    
                    StatCard(
                        icon: "timer",
                        label: "Distracted Time",
                        value: recorder.formattedDistractionTime,
                        valueColor: .brandWarning
                    )
                }
                .padding(.bottom, 32)

                // Done
                Button {
                    let session = StudySession(
                        id: UUID(),
                        date: Date(),
                        name: title,
                        elapsedTime: recorder.elapsedTime,  // already set to study-only time for pomodoro in finishSession()
                        focusedTime: recorder.totalFocusedTime,
                        potentialDistractionTime: recorder.totalPotentialDistractionTime,
                        distractionTime: recorder.totalDistractionTime,
                        distractionCount: recorder.distractionCount,
                        focusScore: recorder.focusScore
                    )
                    store.save(session)
                    achievements.evaluate(against: store)
                    recorder.reset()
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
        .onAppear {
            if title.isEmpty {
                title = PostSessionView.makeTitle()
            }
        }
    }
}

// MARK: - VIEW 4: ANALYTICS

struct AnalyticsView: View {
    @ObservedObject var store: SessionStore

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
                    MiniStatCard(icon: "flame",
                                 iconColor: .brandWarning,
                                 label: "Streak",
                                 value: "\(store.streak) day\(store.streak == 1 ? "" : "s")")
                    MiniStatCard(icon: "chart.line.uptrend.xyaxis",
                                 iconColor: .brandSecondary,
                                 label: "Avg Score",
                                 value: store.sessions.isEmpty ? "--" : "\(store.averageScore)%")
                    MiniStatCard(icon: nil,
                                 iconColor: .clear,
                                 label: "Sessions",
                                 value: "\(store.totalSessions)")
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

                    let heatmap = store.heatmapData
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 3) {
                            ForEach(0..<heatmap.count, id: \.self) { w in
                                VStack(spacing: 3) {
                                    ForEach(0..<heatmap[w].count, id: \.self) { d in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(heatmapColors[heatmap[w][d]])
                                            .frame(width: 18, height: 18)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 12)

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

                if store.sessions.isEmpty {
                    Text("No sessions yet. Complete a focus session to see your history here.")
                        .font(.system(size: 14))
                        .foregroundColor(.textMuted)
                        .padding(.bottom, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.sessions.prefix(20)) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.formattedDate)
                                        .font(.system(size: 12)).foregroundColor(.textMuted)
                                    Text(session.name)
                                        .font(.system(size: 14, weight: .medium)).foregroundColor(.textMain)
                                    Text(session.formattedDuration)
                                        .font(.system(size: 12)).foregroundColor(.textMuted)
                                }
                                Spacer()
                                Text("\(session.focusScore)%")
                                    .font(.system(size: 24, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(scoreColor(session.focusScore))
                            }
                            .padding(20)
                            .background(Color.bgSurface)
                            .cornerRadius(32)
                        }
                    }
                    .padding(.bottom, 110)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }
}

// MARK: - VIEW 5: SETTINGS

struct SettingsView: View {
    @AppStorage("settings.notifications") private var notifications = true
    @AppStorage("settings.haptics")       private var haptics       = true
    @AppStorage("settings.dnd")           private var dnd           = false
    
    var store: SessionStore
    var achievements: AchievementStore
    
    var body: some View {
        NavigationStack {
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
                        
                        NavigationLink {
                            PrivacyView(store: store, achievements: achievements).navigationBarBackButtonHidden(false)
                        } label: {
                            SettingLinkRowLabel(icon: "shield", label: "Privacy", description: "Data & permissions")
                        }
                        Divider().background(Color.surfaceMid).padding(.horizontal, 20)
                        
                        NavigationLink {
                            AboutView().navigationBarBackButtonHidden(false)
                        } label: {
                            SettingLinkRowLabel(icon: "info.circle", label: "About", description: "Version 1.0.0")
                        }
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

// Rename and remove the chevron:
struct SettingLinkRowLabel: View {
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
                Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(.textMain)
                Text(description).font(.system(size: 12)).foregroundColor(.textMuted)
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

struct AchievementToast: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 18))
                .foregroundColor(.textInverse)
                .frame(width: 40, height: 40)
                .background(Color.textInverse.opacity(0.2))
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textInverse.opacity(0.7))
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textInverse)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.brandPrimary)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}

struct PrivacyView: View {
    @AppStorage("studysense.sessions") private var sessionsData: Data = Data()
    @AppStorage("studysense.achievements") private var achievementsData: Data = Data()

    @State private var cameraStatus: String = ""
    @State private var motionAvailable: Bool = false
    @State private var showDeleteConfirm = false

    var store: SessionStore
    var achievements: AchievementStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                Text("Privacy")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 4)
                Text("How StudySense uses your data")
                    .font(.system(size: 14))
                    .foregroundColor(.textMuted)
                    .padding(.bottom, 24)

                // Data collection
                VStack(alignment: .leading, spacing: 0) {
                    PrivacySectionHeader(icon: "internaldrive", title: "Data Storage")
                    Divider().background(Color.surfaceMid)
                    PrivacyRow(
                        icon: "iphone",
                        title: "Stored Locally",
                        description: "All session data, achievements, and settings are stored only on your device. Nothing is uploaded to any server."
                    )
                    Divider().background(Color.surfaceMid)
                    PrivacyRow(
                        icon: "person.slash",
                        title: "No Account Required",
                        description: "StudySense does not collect any personal information or require you to create an account."
                    )
                    Divider().background(Color.surfaceMid)
                    PrivacyRow(
                        icon: "chart.bar.xaxis",
                        title: "No Analytics",
                        description: "No third-party analytics or tracking SDKs are included in this app."
                    )
                }
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 16)

                // Permissions
                VStack(alignment: .leading, spacing: 0) {
                    PrivacySectionHeader(icon: "lock.shield", title: "Permissions")
                    Divider().background(Color.surfaceMid)
                    PrivacyRow(
                        icon: "camera",
                        title: "Camera — \(cameraStatus)",
                        description: "Used only to measure ambient light during a session to detect if your phone is face down. No photos or video are ever saved."
                    )
                    Divider().background(Color.surfaceMid)
                    PrivacyRow(
                        icon: "gyroscope",
                        title: "Motion — \(motionAvailable ? "Available" : "Unavailable")",
                        description: "Accelerometer and gyroscope data is used only during a session to detect movement. No motion data is stored or transmitted."
                    )
                    Divider().background(Color.surfaceMid)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 16))
                                .foregroundColor(.textMuted)
                                .frame(width: 36, height: 36)
                                .background(Color.surfaceMid)
                                .cornerRadius(10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Open iOS Settings")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.brandPrimary)
                                Text("Manage app permissions")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                    }
                }
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 16)

                // Danger zone
                VStack(alignment: .leading, spacing: 0) {
                    PrivacySectionHeader(icon: "trash", title: "Data Management")
                    Divider().background(Color.surfaceMid)
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .frame(width: 36, height: 36)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delete All Data")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                Text("Permanently removes all sessions and achievements")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                    }
                }
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
        .onAppear { refreshPermissionStatus() }
        .alert("Delete All Data", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.deleteAll()
                achievements.resetAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your sessions, achievements, and stats. This cannot be undone.")
        }
    }

    private func refreshPermissionStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:    cameraStatus = "Allowed"
        case .denied:        cameraStatus = "Denied"
        case .restricted:    cameraStatus = "Restricted"
        case .notDetermined: cameraStatus = "Not Asked"
        @unknown default:    cameraStatus = "Unknown"
        }
        motionAvailable = CMMotionManager().isDeviceMotionAvailable
    }
}

struct PrivacySectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textMuted)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
    }
}

struct PrivacyRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.textMuted)
                .frame(width: 36, height: 36)
                .background(Color.surfaceMid)
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textMain)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}


struct AboutView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                Text("About")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textMain)
                    .padding(.bottom, 4)
                Text("StudySense v1.0.0")
                    .font(.system(size: 14))
                    .foregroundColor(.textMuted)
                    .padding(.bottom, 24)

                // App hero block
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.brandPrimary)
                            .frame(width: 80, height: 80)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 36))
                            .foregroundColor(.textInverse)
                    }
                    VStack(spacing: 6) {
                        Text("StudySense")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.textMain)
                        Text("Focus smarter, not harder.")
                            .font(.system(size: 14))
                            .foregroundColor(.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 16)

                // Mission
                VStack(alignment: .leading, spacing: 0) {
                    PrivacySectionHeader(icon: "lightbulb", title: "Mission")
                    Divider().background(Color.surfaceMid)
                    Text("StudySense was built to help students understand their focus habits. By using your phone's sensors — not your attention — it quietly tracks when you're truly locked in versus when you've drifted, so you can study smarter over time.")
                        .font(.system(size: 14))
                        .foregroundColor(.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(20)
                }
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 16)

                // Credits
                VStack(alignment: .leading, spacing: 0) {
                    PrivacySectionHeader(icon: "person.2", title: "Credits")
                    Divider().background(Color.surfaceMid)
                    AboutRow(icon: "hammer.fill",    title: "Designed & Built by", value: "Pruthak Patel, Kunisha Dorasami, Sandro Karkusashvili, Samantha Nyazema")
                    Divider().background(Color.surfaceMid)
                    AboutRow(icon: "swift",           title: "Built with",          value: "SwiftUI")
                    Divider().background(Color.surfaceMid)
                    AboutRow(icon: "iphone.sensors.landscape", title: "Powered by", value: "CoreMotion & AVFoundation")
                }
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 16)

                // Links
                VStack(alignment: .leading, spacing: 0) {
                    PrivacySectionHeader(icon: "link", title: "Support")
                    Divider().background(Color.surfaceMid)
                    Link(destination: URL(string: "mailto:FakeEmail@FakeEmail.com")!) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 16))
                                .foregroundColor(.textMuted)
                                .frame(width: 36, height: 36)
                                .background(Color.surfaceMid)
                                .cornerRadius(10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contact Support")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.brandPrimary)
                                Text("FakeEmail@FakeEmail.com")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                    }
                    Divider().background(Color.surfaceMid)
                    Link(destination: URL(string: "https://apps.apple.com")!) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.textMuted)
                                .frame(width: 36, height: 36)
                                .background(Color.surfaceMid)
                                .cornerRadius(10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rate StudySense")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.brandPrimary)
                                Text("Enjoying the app? Leave a review!")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                    }
                }
                .background(Color.bgSurface)
                .cornerRadius(32)
                .padding(.bottom, 16)

                Text("Made with ♥ by Pruthak Patel")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }
}

struct AboutRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.textMuted)
                .frame(width: 36, height: 36)
                .background(Color.surfaceMid)
                .cornerRadius(10)
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textMain)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

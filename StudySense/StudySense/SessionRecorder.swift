//
//  SessionRecorder.swift
//  StudySense
//
//  Created by Pruthak Patel on 2/26/26.
//

import Foundation
import Combine

enum PhoneState {
    case focused
    case potentiallyDistracted
    case distracted
}

// MARK: - Pomodoro Phase

enum PomodoroPhase {
    case study
    case breakTime
}

@MainActor
final class SessionRecorder: ObservableObject {
    
    let motion = MotionManager()
    let luminance = LuminanceManager()
    
    @Published var isRunning = false
    @Published var isPaused = false
    
    @Published var elapsedTime: TimeInterval = 0
    
    @Published var totalPotentialDistractionTime: TimeInterval = 0
    @Published var totalDistractionTime: TimeInterval = 0
    @Published var distractionCount: Int = 0
    
    @Published var phoneState: PhoneState = .focused
    
    @Published var timerDidComplete: Bool = false
    @Published var isTimerMode: Bool = false
    var timerDuration: TimeInterval = 0

    var remainingTime: TimeInterval {
        max(0, timerDuration - elapsedTime)
    }

    var timerProgress: Double {
        guard timerDuration > 0 else { return 0 }
        return min(1, elapsedTime / timerDuration)
    }

    var formattedRemainingTime: String {
        let t = Int(remainingTime)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    // MARK: - Pomodoro State
    
    @Published var isPomodoroMode: Bool = false
    @Published var pomodoroPhase: PomodoroPhase = .study
    @Published var pomodoroRound: Int = 1
    @Published var pomodoroPhaseDidChange: Bool = false  // triggers haptic + UI
    
    /// Duration of one study block (set by user)
    var pomodorStudyDuration: TimeInterval = 25 * 60
    /// Duration of one break block (set by user)
    var pomodoroBreakDuration: TimeInterval = 5 * 60
    
    /// Elapsed seconds within the *current* phase (study or break)
    @Published var pomodoroPhaseElapsed: TimeInterval = 0
    
    /// How long the current phase lasts
    var pomodoroCurrentPhaseDuration: TimeInterval {
        pomodoroPhase == .study ? pomodorStudyDuration : pomodoroBreakDuration
    }
    
    /// 0 → 1 progress within the current phase
    var pomodoroPhaseProgress: Double {
        guard pomodoroCurrentPhaseDuration > 0 else { return 0 }
        return min(1, pomodoroPhaseElapsed / pomodoroCurrentPhaseDuration)
    }
    
    var pomodoroPhaseRemaining: TimeInterval {
        max(0, pomodoroCurrentPhaseDuration - pomodoroPhaseElapsed)
    }
    
    var formattedPomodoroPhaseRemaining: String {
        let t = Int(pomodoroPhaseRemaining)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    /// Total *study* time accumulated across all completed study rounds plus current study round
    var pomodoroTotalStudyTime: TimeInterval {
        _pomodoroAccumulatedStudyTime + (pomodoroPhase == .study ? pomodoroPhaseElapsed : 0)
    }
    
    private var _pomodoroAccumulatedStudyTime: TimeInterval = 0
    private var pomodoroPhaseStartDate: Date?
    private var pomodoroPhaseTimer: Timer?
    
    // MARK: - Existing internal state
    
    private var sessionStartDate: Date?
    private var pauseStartedAt: Date?
    private var accumulatedPausedDuration: TimeInterval = 0
    private var timer: Timer?
    
    private var stateTimer: Timer?
    private var lastStateSampleDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Start (standard)
    func start(timerDuration: TimeInterval = 0) {
        guard !isRunning else { return }

        isTimerMode = timerDuration > 0
        isPomodoroMode = false
        self.timerDuration = timerDuration
        
        resetSessionDataOnly()
        
        isRunning = true
        isPaused = false
        sessionStartDate = Date()
        pauseStartedAt = nil
        accumulatedPausedDuration = 0
        
        bindMotionCallbacks()
        bindStateObservers()
        
        startTimer()
        startStateTimer()
        
        motion.startUpdates(hz: 50)
        luminance.start()

        if !luminance.hasCameraPermission {
            phoneState = .focused
        } else {
            updatePhoneState()
        }
    }
    
    // MARK: - Start Pomodoro
    
    func startPomodoro(studyMinutes: Int, breakMinutes: Int) {
        guard !isRunning else { return }
        
        pomodorStudyDuration = TimeInterval(studyMinutes * 60)
        pomodoroBreakDuration = TimeInterval(breakMinutes * 60)
        
        isPomodoroMode = true
        isTimerMode = false
        timerDuration = 0
        pomodoroPhase = .study
        pomodoroRound = 1
        pomodoroPhaseElapsed = 0
        _pomodoroAccumulatedStudyTime = 0
        pomodoroPhaseDidChange = false
        
        resetSessionDataOnly()
        
        isRunning = true
        isPaused = false
        sessionStartDate = Date()
        pauseStartedAt = nil
        accumulatedPausedDuration = 0
        pomodoroPhaseStartDate = Date()
        
        bindMotionCallbacks()
        bindStateObservers()
        
        startTimer()
        startStateTimer()
        startPomodoroPhaseTimer()
        
        motion.startUpdates(hz: 50)
        luminance.start()
        
        if !luminance.hasCameraPermission {
            phoneState = .focused
        } else {
            updatePhoneState()
        }
    }
    
    // MARK: - Pause
    func pause() {
        guard isRunning, !isPaused else { return }
        
        sampleStateTime()
        
        isPaused = true
        pauseStartedAt = Date()
        
        timer?.invalidate()
        timer = nil
        
        stateTimer?.invalidate()
        stateTimer = nil
        
        pomodoroPhaseTimer?.invalidate()
        pomodoroPhaseTimer = nil
        
        motion.stopUpdates()
        luminance.stop()
    }
    
    // MARK: - Resume
    func resume() {
        guard isRunning, isPaused else { return }
        
        isPaused = false
        
        if let pauseStartedAt {
            accumulatedPausedDuration += Date().timeIntervalSince(pauseStartedAt)
        }
        self.pauseStartedAt = nil
        
        lastStateSampleDate = Date()
        
        startTimer()
        startStateTimer()
        
        if isPomodoroMode {
            startPomodoroPhaseTimer()
        }
        
        motion.startUpdates(hz: 50)
        luminance.start()

        if !luminance.hasCameraPermission {
            phoneState = .focused
        } else {
            updatePhoneState()
        }
    }
    
    // MARK: - Finish
    func finishSession() {
        guard isRunning else { return }
        
        sampleStateTime()
        updateElapsedTime()
        
        // For pomodoro: use accumulated study time as the "elapsed" time for the session record
        if isPomodoroMode {
            elapsedTime = pomodoroTotalStudyTime
        }
        
        isRunning = false
        isPaused = false
        
        timer?.invalidate()
        timer = nil
        
        stateTimer?.invalidate()
        stateTimer = nil
        
        pomodoroPhaseTimer?.invalidate()
        pomodoroPhaseTimer = nil
        
        motion.stopUpdates()
        luminance.stop()
    }
    
    // MARK: - Reset
    func reset() {
        isRunning = false
        isPaused = false
        
        timer?.invalidate()
        timer = nil
        
        stateTimer?.invalidate()
        stateTimer = nil
        
        pomodoroPhaseTimer?.invalidate()
        pomodoroPhaseTimer = nil
        
        sessionStartDate = nil
        pauseStartedAt = nil
        accumulatedPausedDuration = 0
        lastStateSampleDate = nil
        pomodoroPhaseStartDate = nil
        
        timerDidComplete = false
        isPomodoroMode = false
        pomodoroPhaseDidChange = false
        pomodoroRound = 1
        pomodoroPhase = .study
        pomodoroPhaseElapsed = 0
        _pomodoroAccumulatedStudyTime = 0
        
        resetSessionDataOnly()
        
        motion.stopUpdates()
        luminance.stop()
        
        cancellables.removeAll()
    }
    
    private func resetSessionDataOnly() {
        elapsedTime = 0
        totalPotentialDistractionTime = 0
        totalDistractionTime = 0
        distractionCount = 0
        phoneState = .focused
    }
    
    // MARK: - Pomodoro Phase Timer
    
    private func startPomodoroPhaseTimer() {
        pomodoroPhaseTimer?.invalidate()
        pomodoroPhaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePomodoroPhaseTime()
        }
    }
    
    private func updatePomodoroPhaseTime() {
        guard isRunning, !isPaused, isPomodoroMode else { return }
        guard let start = pomodoroPhaseStartDate else { return }
        
        pomodoroPhaseElapsed = Date().timeIntervalSince(start)
        
        // Check if current phase is complete
        if pomodoroPhaseElapsed >= pomodoroCurrentPhaseDuration {
            transitionPomodoroPhase()
        }
    }
    
    private func transitionPomodoroPhase() {
        if pomodoroPhase == .study {
            // Study → Break: bank the study time
            _pomodoroAccumulatedStudyTime += pomodorStudyDuration
            pomodoroPhase = .breakTime
            // Pause sensors during break
            sampleStateTime()
            motion.stopUpdates()
            luminance.stop()
            stateTimer?.invalidate()
            stateTimer = nil
        } else {
            // Break → Study: resume sensors
            pomodoroRound += 1
            pomodoroPhase = .study
            startStateTimer()
            motion.startUpdates(hz: 50)
            luminance.start()
            if !luminance.hasCameraPermission {
                phoneState = .focused
            } else {
                updatePhoneState()
            }
        }
        
        // Reset phase clock
        pomodoroPhaseElapsed = 0
        pomodoroPhaseStartDate = Date()
        pomodoroPhaseDidChange = true
        
        // Reset flag after a beat so repeated transitions can re-trigger
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.pomodoroPhaseDidChange = false
        }
    }
    
    // MARK: - Motion / state helpers
    
    private func bindMotionCallbacks() {
        motion.onDistractionStart = { [weak self] in
            guard let self else { return }
            self.distractionCount += 1
        }
    }
    
    private func bindStateObservers() {
        cancellables.removeAll()
        
        motion.$isDistracted
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.sampleStateTime()
                self?.updatePhoneState()
            }
            .store(in: &cancellables)
        
        luminance.$isDark
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.sampleStateTime()
                self?.updatePhoneState()
            }
            .store(in: &cancellables)
    }
    
    private func updatePhoneState() {
        // Don't update phone state during a pomodoro break
        if isPomodoroMode && pomodoroPhase == .breakTime {
            phoneState = .focused
            return
        }
        
        guard luminance.hasCameraPermission else {
            phoneState = motion.isDistracted ? .distracted : .focused
            return
        }

        if luminance.isDark {
            phoneState = .focused
        } else if motion.isDistracted {
            phoneState = .distracted
        } else {
            phoneState = .potentiallyDistracted
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func startStateTimer() {
        stateTimer?.invalidate()
        lastStateSampleDate = Date()
        
        stateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.sampleStateTime()
        }
    }
    
    private func updateElapsedTime() {
        guard let sessionStartDate else { return }
        
        let now = Date()
        let pausedExtra: TimeInterval
        
        if let pauseStartedAt, isPaused {
            pausedExtra = now.timeIntervalSince(pauseStartedAt)
        } else {
            pausedExtra = 0
        }
        
        if isTimerMode, !timerDidComplete, elapsedTime >= timerDuration {
            timerDidComplete = true
            pause()
        }
        
        // For pomodoro mode, elapsedTime tracks wall clock (for display only);
        // actual study time is tracked via pomodoroTotalStudyTime
        elapsedTime = now.timeIntervalSince(sessionStartDate) - accumulatedPausedDuration - pausedExtra
    }
    
    private func sampleStateTime() {
        guard isRunning, !isPaused else { return }
        // Don't sample distraction during a pomodoro break
        if isPomodoroMode && pomodoroPhase == .breakTime { return }
        
        let now = Date()
        
        guard let last = lastStateSampleDate else {
            lastStateSampleDate = now
            return
        }
        
        let delta = now.timeIntervalSince(last)
        lastStateSampleDate = now
        
        guard delta > 0 else { return }
        
        switch phoneState {
        case .focused:
            break
        case .potentiallyDistracted:
            totalPotentialDistractionTime += delta
        case .distracted:
            totalDistractionTime += delta
        }
    }
    
    // MARK: - Computed properties
    
    var totalFocusedTime: TimeInterval {
        max(0, elapsedTime - totalPotentialDistractionTime - totalDistractionTime)
    }
    
    var focusScore: Int {
        guard elapsedTime > 0 else { return 0 }
        let weightedBadTime = totalPotentialDistractionTime * 0.5 + totalDistractionTime
        let focusedTime = max(0, elapsedTime - weightedBadTime)
        return Int((focusedTime / elapsedTime) * 100)
    }
    
    var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedPotentialDistractionTime: String {
        let t = Int(totalPotentialDistractionTime)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    var formattedDistractionTime: String {
        let t = Int(totalDistractionTime)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
}

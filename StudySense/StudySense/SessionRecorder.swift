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
    var timerDuration: TimeInterval = 0   // total seconds set by user

    var remainingTime: TimeInterval {
        max(0, timerDuration - elapsedTime)
    }

    var timerProgress: Double {          // 0.0 → 1.0 (full → empty)
        guard timerDuration > 0 else { return 0 }
        return min(1, elapsedTime / timerDuration)
    }

    var formattedRemainingTime: String {
        let t = Int(remainingTime)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    private var sessionStartDate: Date?
    private var pauseStartedAt: Date?
    private var accumulatedPausedDuration: TimeInterval = 0
    private var timer: Timer?
    
    private var stateTimer: Timer?
    private var lastStateSampleDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Start
    func start(timerDuration: TimeInterval = 0) {
        guard !isRunning else { return }

        isTimerMode = timerDuration > 0
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
        }
        else {
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
        
        motion.startUpdates(hz: 50)
        luminance.start()

        if !luminance.hasCameraPermission {
            phoneState = .focused
        }
        else {
            updatePhoneState()
        }
    }
    
    // MARK: - Finish
    func finishSession() {
        guard isRunning else { return }
        
        sampleStateTime()
        updateElapsedTime()
        
        isRunning = false
        isPaused = false
        
        timer?.invalidate()
        timer = nil
        
        stateTimer?.invalidate()
        stateTimer = nil
        
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
        
        sessionStartDate = nil
        pauseStartedAt = nil
        accumulatedPausedDuration = 0
        lastStateSampleDate = nil
        
        timerDidComplete = false
        
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
            pause()  // stops the clock without navigating away
        }
        
        elapsedTime = now.timeIntervalSince(sessionStartDate) - accumulatedPausedDuration - pausedExtra
    }
    
    private func sampleStateTime() {
        guard isRunning, !isPaused else { return }
        
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
    
    //used for post session view
    var totalFocusedTime: TimeInterval {
        max(0, elapsedTime - totalPotentialDistractionTime - totalDistractionTime)
    }
    
    // Weighted score:
    // Potentially distracted counts half as much as fully distracted
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

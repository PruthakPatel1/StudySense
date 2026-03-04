//
//  SessionRecorder.swift
//  StudySense
//
//  Created by Pruthak Patel on 2/26/26.
//

import Foundation
import Combine

@MainActor
final class SessionRecorder: ObservableObject {
    
    let motion = MotionManager() //MotionManager
    
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var totalDistractionTime: TimeInterval = 0
    @Published var distractionCount: Int = 0
    
    private var startDate: Date?
    private var pausedTime: TimeInterval = 0
    private var timer: Timer?
    
    // MARK: - Start
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        elapsedTime = 0
        pausedTime = 0
        startDate = Date()
        
        startTimer()
        
        totalDistractionTime = 0
        distractionCount = 0
        
        motion.onDistractionStart = { [weak self] in
            guard let self else { return }
            self.distractionCount += 1
        }
        
        motion.onDistractionEnd = { [weak self] duration in
            guard let self else { return }
            self.totalDistractionTime += duration
        }
        
        motion.startUpdates(hz: 50) //MotionManager
    }
    
    // MARK: - Pause
    func pause() {
        guard isRunning, !isPaused else { return }
        
        isPaused = true
        pausedTime = elapsedTime
        timer?.invalidate()
        timer = nil
        
        motion.stopUpdates() //MotionManger
    }
    
    // MARK: - Resume
    func resume() {
        guard isRunning, isPaused else { return }
        
        isPaused = false
        startDate = Date().addingTimeInterval(-pausedTime)
        startTimer()
        
        motion.startUpdates(hz: 50) //MotionManager
    }
    
    // MARK: - Stop
    func stop() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        elapsedTime = 0
        pausedTime = 0
        startDate = nil
        
        motion.stopUpdates() //MotionManager
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let startDate = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(startDate)
        }
    }
    
    // MARK: - Formatted Time
    var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

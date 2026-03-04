//
//  MotionManager.swift
//  StudySense
//
//  Created by Pruthak Patel on 2/26/26.
//

import Foundation
import CoreMotion
import Combine

@MainActor
final class MotionManager: ObservableObject {
    
    // Raw-ish outputs for UI
    @Published var accel: (x: Double, y: Double, z: Double) = (0,0,0) // userAcceleration
    @Published var gyro:  (x: Double, y: Double, z: Double) = (0,0,0) // rotationRate
    @Published var isDistracted: Bool = false
    
    // Callbacks for SessionRecorder to subscribe to
    var onDistractionStart: (() -> Void)?
    var onDistractionEnd: ((TimeInterval) -> Void)?  // duration
    
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    
    // ---- Detection parameters (tune) ----
    private let hzDefault: Double = 50
    
    private var startGyro: Double = 0.35
    private var startAccel: Double = 0.20
    
    private var endGyro: Double = 0.12
    private var endAccel: Double = 0.08
    private var settleSeconds: TimeInterval = 1.0
    private var minEpisodeSeconds: TimeInterval = 0.5
    
    // ---- State ----
    private var inEpisode = false
    private var episodeStartT: TimeInterval = 0
    private var stableStartT: TimeInterval? = nil
    private var lastAccelMag: Double? = nil
    private var sessionStartDate: Date? = nil
    
    func startUpdates(hz: Double = 50) {
        let interval = 1.0 / hz
        sessionStartDate = Date()
        
        // Prefer deviceMotion so accel+gyro are time-aligned
        guard manager.isDeviceMotionAvailable else {
            // fallback: your current accel+gyro approach
            startFallbackSeparateSensors(hz: hz)
            return
        }
        
        manager.deviceMotionUpdateInterval = interval
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            
            // Use userAcceleration (gravity removed) + rotationRate
            let ax = m.userAcceleration.x
            let ay = m.userAcceleration.y
            let az = m.userAcceleration.z
            
            let gx = m.rotationRate.x
            let gy = m.rotationRate.y
            let gz = m.rotationRate.z
            
            let t = self.elapsedSinceStart()
            
            Task { @MainActor in
                self.accel = (ax, ay, az)
                self.gyro  = (gx, gy, gz)
                
                self.ingest(t: t, ax: ax, ay: ay, az: az, gx: gx, gy: gy, gz: gz)
            }
        }
    }
    
    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
        manager.stopAccelerometerUpdates()
        manager.stopGyroUpdates()
        
        // If session ends while distracted, close it
        if inEpisode {
            let endT = elapsedSinceStart()
            let dur = endT - episodeStartT
            if dur >= minEpisodeSeconds {
                onDistractionEnd?(dur)
            }
        }
        
        inEpisode = false
        isDistracted = false
        stableStartT = nil
        lastAccelMag = nil
        sessionStartDate = nil
    }
    
    // MARK: - Core detector (state machine)
    private func ingest(t: TimeInterval,
                        ax: Double, ay: Double, az: Double,
                        gx: Double, gy: Double, gz: Double) {
        
        let aMag = sqrt(ax*ax + ay*ay + az*az)
        let gMag = sqrt(gx*gx + gy*gy + gz*gz)
        
        let aDelta: Double
        if let last = lastAccelMag { aDelta = abs(aMag - last) } else { aDelta = 0 }
        lastAccelMag = aMag
        
        let active = (gMag >= startGyro) || (aDelta >= startAccel)
        let stable = (gMag <= endGyro) && (aDelta <= endAccel)
        
        if !inEpisode {
            if active {
                inEpisode = true
                episodeStartT = t
                stableStartT = nil
                isDistracted = true
                onDistractionStart?()
            }
        } else {
            if stable {
                if stableStartT == nil { stableStartT = t }
                if let s = stableStartT, (t - s) >= settleSeconds {
                    let endT = s
                    let dur = endT - episodeStartT
                    if dur >= minEpisodeSeconds {
                        onDistractionEnd?(dur)
                    }
                    inEpisode = false
                    stableStartT = nil
                    isDistracted = false
                }
            } else {
                stableStartT = nil
            }
        }
    }
    
    private func elapsedSinceStart() -> TimeInterval {
        guard let start = sessionStartDate else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    // MARK: - Fallback (your current approach)
    private func startFallbackSeparateSensors(hz: Double) {
        let interval = 1.0 / hz
        
        if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = interval
            manager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
                guard let self, let d = data else { return }
                Task { @MainActor in
                    self.accel = (d.acceleration.x, d.acceleration.y, d.acceleration.z)
                }
            }
        }
        
        if manager.isGyroAvailable {
            manager.gyroUpdateInterval = interval
            manager.startGyroUpdates(to: queue) { [weak self] data, _ in
                guard let self, let d = data else { return }
                Task { @MainActor in
                    self.gyro = (d.rotationRate.x, d.rotationRate.y, d.rotationRate.z)
                }
            }
        }
    }
}

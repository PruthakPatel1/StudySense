//
//  LuminanceManager.swift
//  StudySense
//
//  Created by Pruthak Patel on 3/10/26.
//

import Foundation
import AVFoundation
import CoreVideo
import Combine

@MainActor
final class LuminanceManager: NSObject, ObservableObject {
    
    @Published var luminance: Double = 0
    @Published var isDark: Bool = true
    @Published var hasCameraPermission: Bool = false
    
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "StudySense.Luminance.SessionQueue")
    private let outputQueue  = DispatchQueue(label: "StudySense.Luminance.OutputQueue")
    
    private var isConfigured = false
    private var isRunning = false
    
    // Tune this on a real device
    private let darkThreshold: Double = 0.15
    
    func start() {
        guard !isRunning else { return }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
            startConfiguredSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.hasCameraPermission = granted
                    if granted {
                        self.startConfiguredSession()
                    }
                }
            }
            
        default:
            hasCameraPermission = false
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
        
        isRunning = false
    }
    
    private func startConfiguredSession() {
        if !isConfigured {
            configureSession()
        }
        
        guard isConfigured else { return }
        guard !isRunning else { return }
        
        isRunning = true
        
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    private func configureSession() {
        guard !isConfigured else { return }
        
        session.beginConfiguration()
        session.sessionPreset = .low
        
        // Rear camera usually makes more sense for “face down / in bag / in pocket”
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                session.commitConfiguration()
                return
            }
            
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
            output.setSampleBufferDelegate(self, queue: outputQueue)
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                session.commitConfiguration()
                return
            }
            
            session.commitConfiguration()
            isConfigured = true
            
        } catch {
            session.commitConfiguration()
            print("LuminanceManager configure error: \(error)")
        }
    }
}

extension LuminanceManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let planeIndex = 0
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex) else { return }
        
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex)
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        let step = 8
        var sum: Double = 0
        var count: Double = 0
        
        for y in stride(from: 0, to: height, by: step) {
            let row = buffer.advanced(by: y * bytesPerRow)
            for x in stride(from: 0, to: width, by: step) {
                sum += Double(row[x]) / 255.0
                count += 1
            }
        }
        
        let averageLuminance = count > 0 ? (sum / count) : 0
        
        Task { @MainActor in
            self.luminance = averageLuminance
            self.isDark = averageLuminance <= self.darkThreshold
        }
    }
}

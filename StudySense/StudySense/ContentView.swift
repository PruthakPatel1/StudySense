//
//  ContentView.swift
//  StudySense
//
//  Created by Pruthak Patel on 2/26/26.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var recorder = SessionRecorder()

    var body: some View {
        VStack(spacing: 40) {

            Text("StudySense")
                .font(.largeTitle)
                .bold()

            Text(recorder.formattedTime)
                .font(.system(size: 60, weight: .bold, design: .rounded))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Accel:")
                Text("x: \(recorder.motion.accel.x, specifier: "%.3f")")
                Text("y: \(recorder.motion.accel.y, specifier: "%.3f")")
                Text("z: \(recorder.motion.accel.z, specifier: "%.3f")")

                Text("Gyro:")
                Text("x: \(recorder.motion.gyro.x, specifier: "%.3f")")
                Text("y: \(recorder.motion.gyro.y, specifier: "%.3f")")
                Text("z: \(recorder.motion.gyro.z, specifier: "%.3f")")
                
                Text("Distractions: \(recorder.distractionCount)")
                Text("Distracted time: \(Int(recorder.totalDistractionTime))s")
                Text(recorder.motion.isDistracted ? "DISTRACTED" : "FOCUSED")
            }
            .font(.system(.footnote, design: .monospaced))
            .padding(.top, 10)
            
            

            HStack(spacing: 20) {

                if !recorder.isRunning {
                    Button("Start") {
                        recorder.start()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if recorder.isRunning && !recorder.isPaused {
                    Button("Pause") {
                        recorder.pause()
                    }
                    .buttonStyle(.bordered)
                }

                if recorder.isRunning && recorder.isPaused {
                    Button("Resume") {
                        recorder.resume()
                    }
                    .buttonStyle(.bordered)
                }

                if recorder.isRunning {
                    Button("Stop") {
                        recorder.stop()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}

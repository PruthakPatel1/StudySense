//
//  DesignSystem.swift
//  StudySense
//
//  Created by Pruthak Patel on 2/26/26.
//

internal import SwiftUI

// MARK: - Color Palette

extension Color {
    // Backgrounds
    static let bgCanvas   = Color(hex: "0F0F11")  // App background
    static let bgSurface  = Color(hex: "1C1C1E")  // Cards / nav pill
    static let surfaceMid = Color(hex: "2A2A2C")  // Dividers, icon wells, outlines
    static let sessionBg  = Color(hex: "0A0A0B")  // Active session (near-black)

    // Brand
    static let brandPrimary   = Color(hex: "E0FF57")  // Neon yellow CTA
    static let brandSecondary = Color(hex: "9AFA90")  // Mint green (focused / heatmap max)
    static let brandWarning   = Color(hex: "F97316")  // Orange (distracted)

    // Text
    static let textMain    = Color.white
    static let textMuted   = Color(hex: "A1A1AA")  // Secondary labels
    static let textDim     = Color(hex: "3A3A3C")  // Active session dim elements
    static let textInverse = Color(hex: "0F0F11")  // Text on neon surfaces

    // Hex initialiser
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.textInverse)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brandPrimary)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.textMuted)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.clear)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.surfaceMid, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Toggle Style

struct NeonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn ? Color.brandPrimary : Color.surfaceMid)
                    .frame(width: 48, height: 28)
                Circle()
                    .fill(configuration.isOn ? Color.textInverse : Color.textMuted)
                    .frame(width: 24, height: 24)
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
    }
}

// MARK: - Card Modifier

struct DataCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(Color.bgSurface)
            .cornerRadius(32)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(DataCardModifier())
    }

    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }

    func outlineButton() -> some View {
        buttonStyle(OutlineButtonStyle())
    }
}

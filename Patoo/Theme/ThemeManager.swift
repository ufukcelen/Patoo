//
//  ThemeManager.swift
//  Patoo
//

import SwiftUI
import Observation

public enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case standard = "varsayilan"
    case gece = "gece"
    case cam = "cam"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .standard: return "Varsayılan"
        case .gece: return "Gece"
        case .cam: return "Cam"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .standard: return "Siber Koyu & Neon Vurgular"
        case .gece: return "Dark Neo & Yumuşak Kontrast"
        case .cam: return "Buzlu Cam & Ortam Işığı"
        }
    }
    
    public var iconName: String {
        switch self {
        case .standard: return "sparkles"
        case .gece: return "moon.stars.fill"
        case .cam: return "cube.transparent.fill"
        }
    }
}

public struct ThemeColors: Sendable {
    public let bgDark: Color
    public let bgSidebar: Color
    public let bgCard: Color
    public let bgCardHover: Color
    public let bgInput: Color
    
    public let cyan: Color
    public let cyanGlow: Color
    public let blue: Color
    public let violet: Color
    public let purpleGlow: Color
    
    public let success: Color
    public let warning: Color
    public let danger: Color
    public let info: Color
    
    public let textPrimary: Color
    public let textSecondary: Color
    public let textTertiary: Color
    
    public let borderSubtle: Color
    public let borderCyan: Color
    public let borderActive: Color
    
    public let isGlass: Bool
    
    // MARK: - Theme 1: Varsayılan (Siber Koyu)
    public static let standard = ThemeColors(
        bgDark: Color(red: 0.043, green: 0.055, blue: 0.078),        // #0B0E14
        bgSidebar: Color(red: 0.055, green: 0.071, blue: 0.102),     // #0E121A
        bgCard: Color(red: 0.086, green: 0.114, blue: 0.165),        // #161D2A
        bgCardHover: Color(red: 0.114, green: 0.149, blue: 0.216),   // #1D2637
        bgInput: Color(red: 0.067, green: 0.086, blue: 0.125),       // #111620
        cyan: Color(red: 0.000, green: 0.824, blue: 1.000),          // #00D2FF
        cyanGlow: Color(red: 0.000, green: 0.824, blue: 1.000).opacity(0.3),
        blue: Color(red: 0.039, green: 0.518, blue: 1.000),          // #0A84FF
        violet: Color(red: 0.545, green: 0.361, blue: 0.965),        // #8B5CF6
        purpleGlow: Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.3),
        success: Color(red: 0.180, green: 0.835, blue: 0.451),       // #2ED573
        warning: Color(red: 1.000, green: 0.650, blue: 0.150),       // #FFA526
        danger: Color(red: 1.000, green: 0.280, blue: 0.350),        // #FF4757
        info: Color(red: 0.200, green: 0.600, blue: 1.000),
        textPrimary: Color.white,
        textSecondary: Color(white: 0.72),
        textTertiary: Color(white: 0.46),
        borderSubtle: Color.white.opacity(0.07),
        borderCyan: Color(red: 0.000, green: 0.824, blue: 1.000).opacity(0.35),
        borderActive: Color(red: 0.000, green: 0.824, blue: 1.000).opacity(0.8),
        isGlass: false
    )
    
    // MARK: - Theme 2: Gece (Dark Neo - Reference Image 2)
    public static let gece = ThemeColors(
        bgDark: Color(hex: "0B0F14"),
        bgSidebar: Color(hex: "111827"),     // Surface
        bgCard: Color(hex: "1A2433"),        // Card
        bgCardHover: Color(hex: "233247"),
        bgInput: Color(hex: "0D131B"),
        cyan: Color(hex: "3B82F6"),          // Primary (Mavi)
        cyanGlow: Color(hex: "3B82F6").opacity(0.35),
        blue: Color(hex: "2563EB"),          // Primary Hover
        violet: Color(hex: "8B5CF6"),        // Accent (Mor)
        purpleGlow: Color(hex: "8B5CF6").opacity(0.35),
        success: Color(hex: "10B981"),       // Secondary (Yeşil)
        warning: Color(hex: "F59E0B"),
        danger: Color(hex: "EF4444"),
        info: Color(hex: "3B82F6"),
        textPrimary: Color(hex: "F8FAFC"),   // Text Primary
        textSecondary: Color(hex: "94A3B8"), // Text Secondary
        textTertiary: Color(hex: "64748B"),  // Text Muted
        borderSubtle: Color(hex: "2A3A4A"),  // Border
        borderCyan: Color(hex: "3B82F6").opacity(0.45),
        borderActive: Color(hex: "3B82F6"),
        isGlass: false
    )
    
    // MARK: - Theme 3: Cam (Liquid Glass - Reference Image 1)
    public static let cam = ThemeColors(
        bgDark: Color(red: 0.04, green: 0.06, blue: 0.11).opacity(0.65),
        bgSidebar: Color(white: 0.08).opacity(0.40),
        bgCard: Color(white: 0.14).opacity(0.32),
        bgCardHover: Color(white: 0.20).opacity(0.48),
        bgInput: Color.black.opacity(0.35),
        cyan: Color(red: 0.000, green: 0.850, blue: 1.000),          // Glowing Cyan
        cyanGlow: Color(red: 0.000, green: 0.850, blue: 1.000).opacity(0.5),
        blue: Color(red: 0.160, green: 0.500, blue: 1.000),
        violet: Color(red: 0.650, green: 0.420, blue: 1.000),        // Glowing Glass Violet
        purpleGlow: Color(red: 0.650, green: 0.420, blue: 1.000).opacity(0.45),
        success: Color(red: 0.200, green: 0.880, blue: 0.550),
        warning: Color(red: 1.000, green: 0.700, blue: 0.200),
        danger: Color(red: 1.000, green: 0.300, blue: 0.400),
        info: Color(red: 0.200, green: 0.650, blue: 1.000),
        textPrimary: Color.white,
        textSecondary: Color(white: 0.85),
        textTertiary: Color(white: 0.60),
        borderSubtle: Color.white.opacity(0.18),                     // Specular glass highlight
        borderCyan: Color(red: 0.000, green: 0.850, blue: 1.000).opacity(0.55),
        borderActive: Color(red: 0.000, green: 0.850, blue: 1.000).opacity(0.9),
        isGlass: true
    )
}

@Observable
@MainActor
public final class ThemeManager {
    public static let shared = ThemeManager()
    
    public var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "patoo_selected_theme")
        }
    }
    
    public var colors: ThemeColors {
        switch currentTheme {
        case .standard: return .standard
        case .gece: return .gece
        case .cam: return .cam
        }
    }
    
    public init() {
        if let saved = UserDefaults.standard.string(forKey: "patoo_selected_theme"),
           let theme = AppTheme(rawValue: saved) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .standard
        }
    }
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

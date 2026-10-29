//
//  PatooTheme.swift
//  Patoo
//

import SwiftUI

enum PatooTheme {
    // MARK: - Color Palette
    // Deep dark navy and near-black surfaces
    static let bgDark = Color(red: 0.043, green: 0.055, blue: 0.078)        // #0B0E14
    static let bgSidebar = Color(red: 0.055, green: 0.071, blue: 0.102)     // #0E121A
    static let bgCard = Color(red: 0.086, green: 0.114, blue: 0.165)        // #161D2A
    static let bgCardHover = Color(red: 0.114, green: 0.149, blue: 0.216)   // #1D2637
    static let bgInput = Color(red: 0.067, green: 0.086, blue: 0.125)       // #111620
    
    // Accents: Electric Blue / Cyan & Neon Violet
    static let cyan = Color(red: 0.000, green: 0.824, blue: 1.000)          // #00D2FF
    static let cyanGlow = Color(red: 0.000, green: 0.824, blue: 1.000).opacity(0.3)
    static let blue = Color(red: 0.039, green: 0.518, blue: 1.000)          // #0A84FF
    static let violet = Color(red: 0.545, green: 0.361, blue: 0.965)        // #8B5CF6
    static let purpleGlow = Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.3)
    
    // Status colors
    static let success = Color(red: 0.180, green: 0.835, blue: 0.451)       // #2ED573
    static let warning = Color(red: 1.000, green: 0.650, blue: 0.150)       // #FFA526
    static let danger = Color(red: 1.000, green: 0.280, blue: 0.350)        // #FF4757
    static let info = Color(red: 0.200, green: 0.600, blue: 1.000)
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.72)
    static let textTertiary = Color(white: 0.46)
    
    // Borders
    static let borderSubtle = Color.white.opacity(0.07)
    static let borderCyan = cyan.opacity(0.35)
    static let borderActive = cyan.opacity(0.8)
    
    // Gradients
    static let cyanVioletGradient = LinearGradient(
        colors: [cyan, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [bgCard, bgCard.opacity(0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers & Styles
struct PatooCardModifier: ViewModifier {
    var isHovered: Bool = false
    var cornerRadius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? PatooTheme.bgCardHover : PatooTheme.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered ? PatooTheme.borderCyan : PatooTheme.borderSubtle, lineWidth: 1)
            )
    }
}

extension View {
    func patooCard(isHovered: Bool = false, cornerRadius: CGFloat = 10) -> some View {
        modifier(PatooCardModifier(isHovered: isHovered, cornerRadius: cornerRadius))
    }
}

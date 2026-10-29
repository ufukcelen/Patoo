//
//  PatooTheme.swift
//  Patoo
//

import SwiftUI

public enum PatooTheme {
    // MARK: - Dynamic Color Palette from ThemeManager
    public static var bgDark: Color { ThemeManager.shared.colors.bgDark }
    public static var bgSidebar: Color { ThemeManager.shared.colors.bgSidebar }
    public static var bgCard: Color { ThemeManager.shared.colors.bgCard }
    public static var bgCardHover: Color { ThemeManager.shared.colors.bgCardHover }
    public static var bgInput: Color { ThemeManager.shared.colors.bgInput }
    
    // Accents
    public static var cyan: Color { ThemeManager.shared.colors.cyan }
    public static var cyanGlow: Color { ThemeManager.shared.colors.cyanGlow }
    public static var blue: Color { ThemeManager.shared.colors.blue }
    public static var violet: Color { ThemeManager.shared.colors.violet }
    public static var purpleGlow: Color { ThemeManager.shared.colors.purpleGlow }
    
    // Status colors
    public static var success: Color { ThemeManager.shared.colors.success }
    public static var warning: Color { ThemeManager.shared.colors.warning }
    public static var danger: Color { ThemeManager.shared.colors.danger }
    public static var info: Color { ThemeManager.shared.colors.info }
    
    // Text colors
    public static var textPrimary: Color { ThemeManager.shared.colors.textPrimary }
    public static var textSecondary: Color { ThemeManager.shared.colors.textSecondary }
    public static var textTertiary: Color { ThemeManager.shared.colors.textTertiary }
    
    // Borders
    public static var borderSubtle: Color { ThemeManager.shared.colors.borderSubtle }
    public static var borderCyan: Color { ThemeManager.shared.colors.borderCyan }
    public static var borderActive: Color { ThemeManager.shared.colors.borderActive }
    
    // Gradients
    public static var cyanVioletGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, violet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    public static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [bgCard, bgCard.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifiers & Styles
public struct PatooCardModifier: ViewModifier {
    var isHovered: Bool = false
    var cornerRadius: CGFloat = 10
    
    public func body(content: Content) -> some View {
        let isGlass = ThemeManager.shared.colors.isGlass
        
        content
            .background(
                Group {
                    if isGlass {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(isHovered ? PatooTheme.bgCardHover : PatooTheme.bgCard)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(.ultraThinMaterial.opacity(0.65))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(isHovered ? PatooTheme.bgCardHover : PatooTheme.bgCard)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered ? PatooTheme.borderCyan : PatooTheme.borderSubtle, lineWidth: 1)
            )
            .shadow(
                color: isGlass ? Color.black.opacity(0.35) : Color.black.opacity(0.18),
                radius: isGlass ? 10 : 4,
                y: isGlass ? 5 : 2
            )
    }
}

extension View {
    public func patooCard(isHovered: Bool = false, cornerRadius: CGFloat = 10) -> some View {
        modifier(PatooCardModifier(isHovered: isHovered, cornerRadius: cornerRadius))
    }
}

//
//  ThemeSelectionCard.swift
//  Patoo
//

import SwiftUI

public struct ThemeSelectionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(theme: AppTheme, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.theme = theme
        self.isSelected = isSelected
        self.onSelect = onSelect
    }
    
    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Miniature UI Preview Box
                ZStack {
                    previewBackground
                    
                    // Mini Window Mockup
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: "FF5F56")).frame(width: 5, height: 5)
                            Circle().fill(Color(hex: "FFBD2E")).frame(width: 5, height: 5)
                            Circle().fill(Color(hex: "27C93F")).frame(width: 5, height: 5)
                            Spacer()
                        }
                        .padding(.top, 4)
                        
                        HStack(spacing: 6) {
                            // Mini Sidebar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(miniSidebarColor)
                                .frame(width: 24, height: 42)
                            
                            // Mini Cards
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    miniCard(accent: miniAccent1)
                                    miniCard(accent: miniAccent2)
                                }
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(miniCardFill)
                                    .frame(height: 18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(miniBorderColor, lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? PatooTheme.cyan : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
                )
                
                // Title & Subtitle + Radio
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: theme.iconName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isSelected ? PatooTheme.cyan : PatooTheme.textSecondary)
                            
                            Text(theme.displayName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isSelected ? PatooTheme.textPrimary : PatooTheme.textSecondary)
                        }
                        
                        Text(theme.subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(PatooTheme.textTertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Radio Selection Indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? PatooTheme.cyan : PatooTheme.textTertiary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? PatooTheme.cyan.opacity(0.08) : (isHovered ? PatooTheme.bgCardHover : PatooTheme.bgCard))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? PatooTheme.cyan.opacity(0.8) : (isHovered ? PatooTheme.borderCyan : PatooTheme.borderSubtle), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? PatooTheme.cyan.opacity(0.2) : Color.clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
    
    // MARK: - Mini Preview Helpers
    @ViewBuilder
    private var previewBackground: some View {
        switch theme {
        case .standard:
            Color(red: 0.043, green: 0.055, blue: 0.078)
        case .gece:
            ZStack {
                Color(hex: "0B0F14")
                // Wave glow
                Ellipse()
                    .fill(Color(hex: "3B82F6").opacity(0.2))
                    .frame(width: 90, height: 40)
                    .blur(radius: 12)
                    .offset(x: 20, y: 30)
            }
        case .cam:
            ZStack {
                Color(red: 0.03, green: 0.05, blue: 0.10)
                Circle()
                    .fill(Color(red: 0.0, green: 0.8, blue: 1.0).opacity(0.35))
                    .frame(width: 60, height: 60)
                    .blur(radius: 14)
                    .offset(x: 30, y: -20)
                Circle()
                    .fill(Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.3))
                    .frame(width: 50, height: 50)
                    .blur(radius: 14)
                    .offset(x: -25, y: 25)
            }
        }
    }
    
    private var miniSidebarColor: Color {
        switch theme {
        case .standard: return Color(red: 0.055, green: 0.071, blue: 0.102)
        case .gece: return Color(hex: "111827")
        case .cam: return Color(white: 0.12).opacity(0.5)
        }
    }
    
    private var miniCardFill: Color {
        switch theme {
        case .standard: return Color(red: 0.086, green: 0.114, blue: 0.165)
        case .gece: return Color(hex: "1A2433")
        case .cam: return Color(white: 0.18).opacity(0.35)
        }
    }
    
    private var miniBorderColor: Color {
        switch theme {
        case .standard: return Color.white.opacity(0.08)
        case .gece: return Color(hex: "2A3A4A")
        case .cam: return Color.white.opacity(0.25)
        }
    }
    
    private var miniAccent1: Color {
        switch theme {
        case .standard: return Color(red: 0.0, green: 0.824, blue: 1.0)
        case .gece: return Color(hex: "3B82F6")
        case .cam: return Color(red: 0.0, green: 0.85, blue: 1.0)
        }
    }
    
    private var miniAccent2: Color {
        switch theme {
        case .standard: return Color(red: 0.545, green: 0.361, blue: 0.965)
        case .gece: return Color(hex: "10B981")
        case .cam: return Color(red: 0.65, green: 0.42, blue: 1.0)
        }
    }
    
    @ViewBuilder
    private func miniCard(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(miniCardFill)
            .frame(height: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(miniBorderColor, lineWidth: 0.5)
            )
            .overlay(
                Circle()
                    .fill(accent)
                    .frame(width: 4, height: 4)
                    .padding(3),
                alignment: .topLeading
            )
    }
}

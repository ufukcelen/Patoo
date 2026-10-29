//
//  PatooButton.swift
//  Patoo
//

import SwiftUI

public enum PatooButtonStyleType {
    case primary
    case secondary
    case danger
    case subtle
}

public struct PatooButton: View {
    let title: String
    var icon: String? = nil
    var style: PatooButtonStyleType = .primary
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    public init(
        _ title: String,
        icon: String? = nil,
        style: PatooButtonStyleType = .primary,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(foregroundColor)
            .background(backgroundView)
            .overlay(borderOverlay)
            .cornerRadius(8)
            .shadow(color: shadowColor, radius: isHovered ? 8 : 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.black
        case .secondary:
            return PatooTheme.textPrimary
        case .danger:
            return PatooTheme.danger
        case .subtle:
            return PatooTheme.cyan
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: isHovered
                    ? [PatooTheme.cyan, Color(red: 0.2, green: 0.9, blue: 1.0)]
                    : [PatooTheme.cyan, PatooTheme.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            isHovered ? PatooTheme.bgCardHover : PatooTheme.bgCard
        case .danger:
            isHovered ? PatooTheme.danger.opacity(0.2) : PatooTheme.danger.opacity(0.1)
        case .subtle:
            isHovered ? PatooTheme.cyan.opacity(0.15) : Color.clear
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? PatooTheme.borderCyan : PatooTheme.borderSubtle, lineWidth: 1)
        case .danger:
            RoundedRectangle(cornerRadius: 8)
                .stroke(PatooTheme.danger.opacity(0.3), lineWidth: 1)
        case .subtle:
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? PatooTheme.cyan.opacity(0.4) : Color.clear, lineWidth: 1)
        }
    }
    
    private var shadowColor: Color {
        guard isHovered && isEnabled else { return Color.clear }
        switch style {
        case .primary:
            return PatooTheme.cyan.opacity(0.4)
        case .danger:
            return PatooTheme.danger.opacity(0.3)
        default:
            return Color.clear
        }
    }
}

//
//  TechnicalHUD.swift
//  Patoo
//

import SwiftUI

// MARK: - Circular HUD Progress Ring
public struct HUDProgressRing: View {
    public var progress: Double // 0.0 to 1.0
    public var size: CGFloat = 48
    public var strokeWidth: CGFloat = 4
    
    public init(progress: Double, size: CGFloat = 48, strokeWidth: CGFloat = 4) {
        self.progress = progress
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: strokeWidth)
            
            // Neon Arc
            Circle()
                .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [PatooTheme.cyan, PatooTheme.violet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: PatooTheme.cyanGlow, radius: 4)
            
            // Percentage Text
            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(size: size * 0.28, weight: .bold, design: .monospaced))
                .foregroundColor(PatooTheme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Job Status Badge
public struct StatusBadge: View {
    public let status: JobStatus
    
    public init(status: JobStatus) {
        self.status = status
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
            
            Text(status.title)
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundColor(indicatorColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(indicatorColor.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(indicatorColor.opacity(0.25), lineWidth: 1)
        )
    }
    
    private var indicatorColor: Color {
        switch status {
        case .pending:
            return PatooTheme.warning
        case .processing:
            return PatooTheme.cyan
        case .completed:
            return PatooTheme.success
        case .failed:
            return PatooTheme.danger
        case .cancelled:
            return PatooTheme.textTertiary
        }
    }
}

// MARK: - Technical Stat Pill
public struct TechnicalStatPill: View {
    public let title: String
    public let value: String
    public var icon: String? = nil
    
    public init(title: String, value: String, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(PatooTheme.cyan)
                }
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(PatooTheme.textTertiary)
            }
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(PatooTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(PatooTheme.bgInput)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(PatooTheme.borderSubtle, lineWidth: 1)
        )
    }
}

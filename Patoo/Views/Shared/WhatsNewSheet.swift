//
//  WhatsNewSheet.swift
//  Patoo
//

import SwiftUI

public struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss
    var updateManager: AppUpdateManager
    
    public init(updateManager: AppUpdateManager = .shared) {
        self.updateManager = updateManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PatooTheme.cyan.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(PatooTheme.cyan)
                        .shadow(color: PatooTheme.cyanGlow, radius: 8)
                }
                
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Patoo Yenilikleri")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text(AppUpdateManager.currentVersion)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(PatooTheme.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PatooTheme.cyan.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text(updateManager.currentChangelog.title)
                        .font(.system(size: 13))
                        .foregroundColor(PatooTheme.textSecondary)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            Divider().background(PatooTheme.borderSubtle)
            
            // Feature List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(updateManager.currentChangelog.features) { feature in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(PatooTheme.bgCard)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                    )
                                
                                Image(systemName: feature.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(PatooTheme.cyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(feature.title)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(PatooTheme.textPrimary)
                                    
                                    if let badge = feature.badge {
                                        Text(badge)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(badgeColor(badge))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(badgeColor(badge).opacity(0.12))
                                            .cornerRadius(3)
                                    }
                                }
                                
                                Text(feature.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(PatooTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(20)
            }
            
            Divider().background(PatooTheme.borderSubtle)
            
            // Footer Action
            HStack {
                Spacer()
                
                Button(action: {
                    updateManager.markVersionAsSeen()
                    dismiss()
                }) {
                    Text("Harika, Başla!")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(PatooTheme.cyan)
                        .cornerRadius(7)
                        .shadow(color: PatooTheme.cyanGlow.opacity(0.5), radius: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(PatooTheme.bgCard)
        }
        .frame(width: 460, height: 480)
        .background(PatooTheme.bgDark)
    }
    
    private func badgeColor(_ badge: String) -> Color {
        switch badge {
        case "YENİ": return PatooTheme.cyan
        case "DÜZELTME": return PatooTheme.success
        case "GÜNCELLEME": return Color.orange
        default: return PatooTheme.textSecondary
        }
    }
}

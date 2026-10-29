//
//  SidebarView.swift
//  Patoo
//

import SwiftUI

public struct SidebarView: View {
    @Binding var selection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    public init(
        selection: Binding<NavigationSection>,
        queueManager: QueueManager,
        appState: AppState
    ) {
        self._selection = selection
        self.queueManager = queueManager
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // App Branding Header
            HStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: PatooTheme.cyanGlow.opacity(0.4), radius: 6)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("PATOO")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("v0.0.1 • FFmpeg Engine")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(PatooTheme.textTertiary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Navigation Items
            VStack(spacing: 4) {
                ForEach(NavigationSection.allCases) { section in
                    SidebarItemRow(
                        section: section,
                        isSelected: selection == section,
                        badgeCount: section == .queue ? (queueManager.pendingCount + (queueManager.isProcessing ? 1 : 0)) : nil
                    ) {
                        selection = section
                    }
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            // Engine Status Indicator at bottom
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.ffmpegInstallation.isReady ? PatooTheme.success : PatooTheme.warning)
                    .frame(width: 8, height: 8)
                    .shadow(color: (appState.ffmpegInstallation.isReady ? PatooTheme.success : PatooTheme.warning).opacity(0.6), radius: 3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.ffmpegInstallation.isReady ? "FFmpeg Hazır" : "FFmpeg Eksik")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text(appState.ffmpegInstallation.isReady ? "Sistem Aktif" : "Ayarları Kontrol Edin")
                        .font(.system(size: 10))
                        .foregroundColor(PatooTheme.textTertiary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(PatooTheme.bgCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(PatooTheme.borderSubtle, lineWidth: 1)
            )
            .padding(12)
        }
        .frame(width: 210)
        .background(PatooTheme.bgSidebar)
    }
}

private struct SidebarItemRow: View {
    let section: NavigationSection
    let isSelected: Bool
    let badgeCount: Int?
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.iconName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? PatooTheme.cyan : (isHovered ? PatooTheme.textPrimary : PatooTheme.textSecondary))
                    .frame(width: 18)
                
                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? PatooTheme.textPrimary : (isHovered ? PatooTheme.textPrimary : PatooTheme.textSecondary))
                
                Spacer()
                
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(PatooTheme.cyan)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? PatooTheme.cyan.opacity(0.12) : (isHovered ? Color.white.opacity(0.04) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? PatooTheme.borderCyan : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

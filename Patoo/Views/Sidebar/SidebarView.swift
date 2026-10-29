//
//  SidebarView.swift
//  Patoo
//

import SwiftUI

public struct SidebarView: View {
    @Binding var selection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    var updateManager: AppUpdateManager
    
    @State private var isHoveringUpdate = false
    
    public init(
        selection: Binding<NavigationSection>,
        queueManager: QueueManager,
        appState: AppState,
        updateManager: AppUpdateManager = .shared
    ) {
        self._selection = selection
        self.queueManager = queueManager
        self.appState = appState
        self.updateManager = updateManager
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
                    
                    HStack(spacing: 4) {
                        Text("v\(AppUpdateManager.currentVersion)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(PatooTheme.cyan)
                        
                        Text("• FFmpeg")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(PatooTheme.textTertiary)
                    }
                }
                
                Spacer()
                
                // What's New button
                Button(action: {
                    updateManager.showWhatsNewModal = true
                }) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(PatooTheme.textTertiary)
                        .padding(6)
                        .background(PatooTheme.bgCard)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Sürüm Yenilikleri")
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Primary Navigation Items (The 6 Main Menus)
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(NavigationSection.allCases.filter { $0.isPrimaryMenuItem }) { section in
                        SidebarItemRow(
                            section: section,
                            isSelected: selection == section,
                            badgeCount: nil,
                            isPinned: appState.isPinned(section)
                        ) {
                            selection = section
                        }
                    }
                    
                    Divider()
                        .background(PatooTheme.borderSubtle)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                    
                    // Queue & Settings
                    SidebarItemRow(
                        section: .queue,
                        isSelected: selection == .queue,
                        badgeCount: (queueManager.pendingCount + (queueManager.isProcessing ? 1 : 0)),
                        isPinned: appState.isPinned(.queue)
                    ) {
                        selection = .queue
                    }
                    
                    SidebarItemRow(
                        section: .settings,
                        isSelected: selection == .settings,
                        badgeCount: nil,
                        isPinned: appState.isPinned(.settings)
                    ) {
                        selection = .settings
                    }
                }
                .padding(.horizontal, 10)
            }
            
            Spacer()
            
            // Update & Status Area
            VStack(spacing: 8) {
                // Update Button
                Button(action: {
                    updateManager.checkForUpdates(showFeedbackIfUpToDate: true)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PatooTheme.cyan)
                        
                        Text("Güncelleme Denetle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isHoveringUpdate ? PatooTheme.cyan.opacity(0.12) : PatooTheme.bgCard)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isHoveringUpdate ? PatooTheme.cyan.opacity(0.4) : PatooTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .onHover { isHoveringUpdate = $0 }
                
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
                .padding(10)
                .background(PatooTheme.bgCard)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                )
            }
            .padding(12)
        }
        .frame(width: 220)
        .background(PatooTheme.bgSidebar)
    }
}

private struct SidebarItemRow: View {
    let section: NavigationSection
    let isSelected: Bool
    let badgeCount: Int?
    var isPinned: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.iconName)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? PatooTheme.cyan : (isHovered ? PatooTheme.textPrimary : PatooTheme.textSecondary))
                    .frame(width: 18)
                
                Text(section.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? PatooTheme.textPrimary : (isHovered ? PatooTheme.textPrimary : PatooTheme.textSecondary))
                
                Spacer()
                
                if isPinned && section.isPinnable {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(PatooTheme.cyan.opacity(0.7))
                }
                
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? .black : PatooTheme.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? PatooTheme.cyan : PatooTheme.cyan.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? PatooTheme.bgCardHover : (isHovered ? PatooTheme.bgCard.opacity(0.5) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? PatooTheme.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

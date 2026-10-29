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
    var ffmpegManager: FFmpegUpdateManager
    
    @State private var isHoveringUpdate = false
    
    public init(
        selection: Binding<NavigationSection>,
        queueManager: QueueManager,
        appState: AppState,
        updateManager: AppUpdateManager = .shared,
        ffmpegManager: FFmpegUpdateManager = .shared
    ) {
        self._selection = selection
        self.queueManager = queueManager
        self.appState = appState
        self.updateManager = updateManager
        self.ffmpegManager = ffmpegManager
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
                        .foregroundColor(PatooTheme.cyan)
                        .padding(6)
                        .background(PatooTheme.bgCard)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Yenilikleri Görüntüle")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            
            Divider()
                .background(PatooTheme.borderSubtle)
            
            // Primary 6 Modules Navigation List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(NavigationSection.primarySections) { section in
                        SidebarItemRow(
                            section: section,
                            isSelected: selection == section,
                            badgeCount: nil,
                            isPinned: appState.isPinned(section)
                        ) {
                            selection = section
                        }
                    }
                    
                    // Divider separating secondary items
                    Rectangle()
                        .fill(PatooTheme.borderSubtle)
                        .frame(height: 1)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                    
                    // Kuyruk
                    SidebarItemRow(
                        section: .queue,
                        isSelected: selection == .queue,
                        badgeCount: queueManager.activeCount > 0 ? queueManager.activeCount : nil,
                        isPinned: false
                    ) {
                        selection = .queue
                    }
                    
                    // Ayarlar
                    SidebarItemRow(
                        section: .settings,
                        isSelected: selection == .settings,
                        badgeCount: nil,
                        isPinned: false
                    ) {
                        selection = .settings
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            
            Divider()
                .background(PatooTheme.borderSubtle)
            
            // Bottom Status & Interactive Engine Button
            VStack(spacing: 8) {
                // Check App Update Bar
                Button(action: {
                    updateManager.checkForUpdates(showFeedbackIfUpToDate: true)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(PatooTheme.cyan)
                        
                        Text("Uygulama Güncelle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PatooTheme.textSecondary)
                        
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
                
                // Interactive FFmpeg Status & Update Button (Yeşil -> Sarı -> Tıkla Güncelle)
                FFmpegStatusButton(appState: appState, ffmpegManager: ffmpegManager)
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
                    .frame(width: 20)
                
                Text(section.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? PatooTheme.textPrimary : (isHovered ? PatooTheme.textPrimary : PatooTheme.textSecondary))
                
                Spacer()
                
                // Pin Indicator
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundColor(PatooTheme.cyan.opacity(0.7))
                }
                
                // Badge Count for Queue
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PatooTheme.cyan)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? PatooTheme.cyan.opacity(0.12) : (isHovered ? PatooTheme.bgCardHover : Color.clear))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? PatooTheme.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

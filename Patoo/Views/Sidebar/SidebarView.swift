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
    
    @AppStorage("pinned_modules_csv") private var pinnedModulesCSV: String = ""
    
    private var pinnedSections: [NavigationSection] {
        let keys = pinnedModulesCSV.split(separator: ",").map(String.init)
        return keys.compactMap { key in
            NavigationSection(rawValue: key)
        }
    }
    
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
            // App Branding Header (Sol Üst Logo - Sabit Renkli & Tüm Temalarda Aktif)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "0E1522"))
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "00D2FF").opacity(0.45), lineWidth: 1.5)
                        )
                        .shadow(color: Color(hex: "00D2FF").opacity(0.35), radius: 6)
                    
                    Image("MainLogo")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .padding(2)
                }
                .frame(width: 36, height: 36)
                
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
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(NavigationSection.primarySections) { section in
                        SidebarItemRow(
                            section: section,
                            isSelected: selection == section,
                            badge: nil,
                            isPinned: pinnedSections.contains(section),
                            onSelect: {
                                selection = section
                            },
                            onTogglePin: {
                                togglePin(for: section)
                            }
                        )
                    }
                    
                    // Secondary Nav / Utilities
                    VStack(alignment: .leading, spacing: 3) {
                        Divider()
                            .background(PatooTheme.borderSubtle)
                            .padding(.vertical, 6)
                        
                        // Queue Row
                        SidebarItemRow(
                            section: .queue,
                            isSelected: selection == .queue,
                            badge: queueManager.activeCount > 0 ? "\(queueManager.activeCount)" : nil,
                            isPinned: false,
                            canPin: false,
                            onSelect: {
                                selection = .queue
                            },
                            onTogglePin: {}
                        )
                        
                        // Settings Row
                        SidebarItemRow(
                            section: .settings,
                            isSelected: selection == .settings,
                            badge: nil,
                            isPinned: false,
                            canPin: false,
                            onSelect: {
                                selection = .settings
                            },
                            onTogglePin: {}
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            
            Spacer()
            
            // Footer: Interactive FFmpeg Status Button
            VStack(spacing: 8) {
                Divider()
                    .background(PatooTheme.borderSubtle)
                
                FFmpegStatusButton(
                    appState: appState,
                    ffmpegManager: ffmpegManager
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 4)
            }
        }
        .frame(width: 220)
        .background(PatooTheme.bgSidebar)
    }
    
    private func togglePin(for section: NavigationSection) {
        var current = pinnedSections
        if let idx = current.firstIndex(of: section) {
            current.remove(at: idx)
        } else {
            current.append(section)
        }
        pinnedModulesCSV = current.map(\.rawValue).joined(separator: ",")
    }
}

// MARK: - Sidebar Item Row Component with Pinning Support
private struct SidebarItemRow: View {
    let section: NavigationSection
    let isSelected: Bool
    let badge: String?
    let isPinned: Bool
    var canPin: Bool = true
    let onSelect: () -> Void
    let onTogglePin: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Section Icon
                Image(systemName: section.iconName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? PatooTheme.cyan : (isHovered ? PatooTheme.textPrimary : PatooTheme.textSecondary))
                    .frame(width: 20)
                
                // Section Title
                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? PatooTheme.textPrimary : (isHovered ? PatooTheme.textPrimary : PatooTheme.textSecondary))
                
                Spacer()
                
                // Pin Indicator / Toggle Button
                if canPin {
                    Button(action: onTogglePin) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                            .foregroundColor(isPinned ? PatooTheme.cyan : PatooTheme.textTertiary.opacity(0.6))
                            .opacity(isPinned || isHovered ? 1 : 0)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help(isPinned ? "Hızlı İşlemlerden Kaldır" : "Hızlı İşlemlere Sabitle")
                }
                
                // Queue Count Badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PatooTheme.cyan)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? PatooTheme.cyan.opacity(0.12) : (isHovered ? PatooTheme.bgCardHover : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? PatooTheme.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

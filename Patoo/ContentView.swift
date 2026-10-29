//
//  ContentView.swift
//  Patoo
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState.shared
    @State private var queueManager = QueueManager.shared
    @State private var updateManager = AppUpdateManager.shared
    @State private var ffmpegManager = FFmpegUpdateManager.shared
    @State private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Theme Background Canvas
            Group {
                switch themeManager.currentTheme {
                case .cam:
                    // Liquid Glass Bokeh & Ambient Mesh (Reference Image 1)
                    ZStack {
                        Color(red: 0.03, green: 0.05, blue: 0.09)
                        
                        // Top Right Glowing Cyan Orb
                        Circle()
                            .fill(Color(red: 0.0, green: 0.75, blue: 1.0).opacity(0.24))
                            .frame(width: 480, height: 480)
                            .blur(radius: 80)
                            .offset(x: 320, y: -220)
                        
                        // Bottom Left Deep Violet Orb
                        Circle()
                            .fill(Color(red: 0.55, green: 0.25, blue: 0.95).opacity(0.22))
                            .frame(width: 520, height: 520)
                            .blur(radius: 90)
                            .offset(x: -120, y: 260)
                        
                        // Bottom Right Amber Bokeh
                        Circle()
                            .fill(Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.12))
                            .frame(width: 320, height: 320)
                            .blur(radius: 70)
                            .offset(x: 380, y: 280)
                    }
                case .gece:
                    // Dark Neo Wave Background (Reference Image 2)
                    ZStack {
                        Color(hex: "0B0F14")
                        
                        // Deep smooth blue wave glow
                        Ellipse()
                            .fill(Color(hex: "3B82F6").opacity(0.12))
                            .frame(width: 720, height: 260)
                            .blur(radius: 70)
                            .offset(x: 80, y: 320)
                    }
                case .standard:
                    PatooTheme.bgDark
                }
            }
            .ignoresSafeArea()
            
            // Main Window Content (Exact Layout & Structure Preserved)
            HStack(spacing: 0) {
                // Sidebar Navigation
                SidebarView(
                    selection: $appState.selectedSection,
                    queueManager: queueManager,
                    appState: appState,
                    updateManager: updateManager,
                    ffmpegManager: ffmpegManager
                )
                
                Divider()
                    .background(PatooTheme.borderSubtle)
                
                // Main Content Area
                ZStack(alignment: .bottom) {
                    Group {
                        switch appState.selectedSection {
                        case .overview:
                            OverviewView(
                                selectedSection: $appState.selectedSection,
                                queueManager: queueManager,
                                appState: appState
                            )
                        case .convert:
                            ConvertView(
                                selectedSection: $appState.selectedSection,
                                queueManager: queueManager,
                                appState: appState
                            )
                        case .compress:
                            CompressView(
                                selectedSection: $appState.selectedSection,
                                queueManager: queueManager,
                                appState: appState
                            )
                        case .audioStudio:
                            AudioStudioView(
                                selectedSection: $appState.selectedSection,
                                queueManager: queueManager,
                                appState: appState
                            )
                        case .batch:
                            BatchProcessView(
                                selectedSection: $appState.selectedSection,
                                queueManager: queueManager,
                                appState: appState
                            )
                        case .mediaInfo:
                            MediaInfoView(
                                selectedSection: $appState.selectedSection,
                                queueManager: queueManager,
                                appState: appState
                            )
                        case .queue:
                            QueueView(queueManager: queueManager)
                        case .settings:
                            SettingsView(
                                appState: appState,
                                updateManager: updateManager,
                                ffmpegManager: ffmpegManager,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Floating Toast Notification Banner
                    if let toast = appState.toast {
                        HStack(spacing: 10) {
                            Image(systemName: toast.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundColor(toast.isError ? PatooTheme.danger : PatooTheme.cyan)
                            
                            Text(toast.message)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(PatooTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(PatooTheme.bgCard)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(toast.isError ? PatooTheme.danger.opacity(0.5) : PatooTheme.cyan.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .frame(minWidth: 980, minHeight: 640)
        .background(PatooTheme.bgDark)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $updateManager.showUpdateModal) {
            AppUpdateSheet(updateManager: updateManager)
        }
        .sheet(isPresented: $updateManager.showWhatsNewModal) {
            WhatsNewSheet(updateManager: updateManager)
        }
    }
}

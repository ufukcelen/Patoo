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
    
    var body: some View {
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
                            ffmpegManager: ffmpegManager
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

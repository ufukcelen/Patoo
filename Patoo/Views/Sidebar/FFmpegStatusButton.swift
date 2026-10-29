//
//  FFmpegStatusButton.swift
//  Patoo
//

import SwiftUI

public struct FFmpegStatusButton: View {
    var appState: AppState
    var ffmpegManager: FFmpegUpdateManager
    
    @State private var isHovering: Bool = false
    
    public init(appState: AppState, ffmpegManager: FFmpegUpdateManager = .shared) {
        self.appState = appState
        self.ffmpegManager = ffmpegManager
    }
    
    public var body: some View {
        Button(action: handleAction) {
            HStack(spacing: 9) {
                // Status Indicator Icon / Spinner
                statusIcon
                
                // Status Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(titleColor)
                    
                    Text(subtitleText)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(PatooTheme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Trailing Action Badge or Arrow
                trailingAccessory
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(backgroundFill)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderStroke, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 4, y: 1)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(tooltipText)
    }
    
    // MARK: - Subcomponents
    @ViewBuilder
    private var statusIcon: some View {
        switch ffmpegManager.status {
        case .downloading:
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 10, height: 10)
        case .checking:
            Circle()
                .fill(PatooTheme.cyan)
                .frame(width: 8, height: 8)
                .opacity(0.8)
        case .updateAvailable:
            Circle()
                .fill(PatooTheme.warning)
                .frame(width: 8, height: 8)
                .shadow(color: PatooTheme.warning.opacity(0.8), radius: 4)
        case .notInstalled, .error:
            Circle()
                .fill(PatooTheme.danger)
                .frame(width: 8, height: 8)
                .shadow(color: PatooTheme.danger.opacity(0.7), radius: 3)
        case .upToDate:
            Circle()
                .fill(PatooTheme.success)
                .frame(width: 8, height: 8)
                .shadow(color: PatooTheme.success.opacity(0.6), radius: 3)
        }
    }
    
    @ViewBuilder
    private var trailingAccessory: some View {
        switch ffmpegManager.status {
        case .updateAvailable:
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PatooTheme.warning)
        case .notInstalled:
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(PatooTheme.cyan)
        case .downloading:
            EmptyView()
        case .checking, .upToDate, .error:
            if isHovering {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 9))
                    .foregroundColor(PatooTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var titleText: String {
        switch ffmpegManager.status {
        case .downloading:
            return "FFmpeg Güncelleniyor..."
        case .checking:
            return "FFmpeg Denetleniyor..."
        case .updateAvailable:
            return "FFmpeg Güncelle"
        case .notInstalled:
            return "FFmpeg Yükle"
        case .error:
            return "FFmpeg Hatası"
        case .upToDate:
            return "FFmpeg Hazır"
        }
    }
    
    private var subtitleText: String {
        switch ffmpegManager.status {
        case .downloading(_, let msg):
            return msg
        case .checking:
            return "Sürüm kontrol ediliyor"
        case .updateAvailable(_, let latest):
            return "v\(latest) Mevcut • Tıkla"
        case .notInstalled:
            return "Tek tıkla kur"
        case .error(let msg):
            return msg
        case .upToDate(let ver):
            return "v\(ver) • Güncel"
        }
    }
    
    private var titleColor: Color {
        switch ffmpegManager.status {
        case .updateAvailable:
            return PatooTheme.warning
        case .notInstalled, .error:
            return PatooTheme.danger
        default:
            return PatooTheme.textPrimary
        }
    }
    
    private var backgroundFill: Color {
        switch ffmpegManager.status {
        case .updateAvailable:
            return isHovering ? PatooTheme.warning.opacity(0.12) : PatooTheme.warning.opacity(0.06)
        case .notInstalled:
            return isHovering ? PatooTheme.cyan.opacity(0.12) : PatooTheme.bgCard
        default:
            return isHovering ? PatooTheme.bgCardHover : PatooTheme.bgCard
        }
    }
    
    private var borderStroke: Color {
        switch ffmpegManager.status {
        case .updateAvailable:
            return PatooTheme.warning.opacity(isHovering ? 0.8 : 0.5)
        case .notInstalled:
            return PatooTheme.cyan.opacity(isHovering ? 0.8 : 0.4)
        default:
            return isHovering ? PatooTheme.borderCyan : PatooTheme.borderSubtle
        }
    }
    
    private var shadowColor: Color {
        switch ffmpegManager.status {
        case .updateAvailable:
            return PatooTheme.warning.opacity(0.2)
        default:
            return Color.clear
        }
    }
    
    private var tooltipText: String {
        switch ffmpegManager.status {
        case .updateAvailable(_, let latest):
            return "Yeni FFmpeg v\(latest) sürümünü otomatik indirmek ve kurmak için tıklayın."
        case .notInstalled:
            return "FFmpeg sisteminizde bulunamadı. Resmi statik sürümü tek tıkla kurmak için tıklayın."
        case .upToDate:
            return "FFmpeg güncel ve çalışmaya hazır. Güncellemeleri yeniden denetlemek için tıklayın."
        case .checking:
            return "Güncellemeler kontrol ediliyor..."
        case .downloading:
            return "FFmpeg indiriliyor ve kuruluyor..."
        case .error(let msg):
            return "Hata: \(msg). Tekrar denemek için tıklayın."
        }
    }
    
    // MARK: - Action
    private func handleAction() {
        guard !ffmpegManager.status.isUpdating else { return }
        
        switch ffmpegManager.status {
        case .updateAvailable, .notInstalled, .error:
            ffmpegManager.performInstallOrUpdate(appState: appState)
        case .upToDate, .checking:
            Task {
                await ffmpegManager.checkForUpdates(appState: appState, silent: false)
            }
        case .downloading:
            break
        }
    }
}

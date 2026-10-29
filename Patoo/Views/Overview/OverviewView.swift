//
//  OverviewView.swift
//  Patoo
//

import SwiftUI

public struct OverviewView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    public init(
        selectedSection: Binding<NavigationSection>,
        queueManager: QueueManager,
        appState: AppState
    ) {
        self._selectedSection = selectedSection
        self.queueManager = queueManager
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Genel Bakış")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("FFmpeg ve FFprobe motoru ile yüksek performanslı yerel medya işleme merkezi.")
                        .font(.system(size: 13))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                
                // Status HUD Cards Grid
                HStack(spacing: 16) {
                    // Engine Status Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "cpu")
                                .font(.system(size: 16))
                                .foregroundColor(PatooTheme.cyan)
                            Text("MOTOR DURUMU")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(PatooTheme.textTertiary)
                            Spacer()
                            Circle()
                                .fill(appState.ffmpegInstallation.isReady ? PatooTheme.success : PatooTheme.warning)
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(appState.ffmpegInstallation.isReady ? "Kullanıma Hazır" : "Yapılandırma Gerekli")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text(appState.ffmpegInstallation.version ?? "FFmpeg ikili dosyası tespit edilemedi")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(PatooTheme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(16)
                    .patooCard()
                    
                    // Hardware Acceleration Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16))
                                .foregroundColor(PatooTheme.violet)
                            Text("DONANIM HIZLANDIRMA")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(PatooTheme.textTertiary)
                            Spacer()
                            Text("Apple Silicon")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(PatooTheme.violet.opacity(0.15))
                                .foregroundColor(PatooTheme.violet)
                                .cornerRadius(4)
                        }
                        
                        Text("VideoToolbox Aktif")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text("H.264 & HEVC kodlamaları için yerel GPU desteği devrede")
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(16)
                    .patooCard()
                    
                    // Queue Status Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "tray.full.fill")
                                .font(.system(size: 16))
                                .foregroundColor(PatooTheme.cyan)
                            Text("İŞLEM KUYRUĞU")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(PatooTheme.textTertiary)
                            Spacer()
                        }
                        
                        Text("\(queueManager.jobs.count) Görev")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text("\(queueManager.completedCount) Tamamlandı • \(queueManager.pendingCount) Bekleyen")
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    .padding(16)
                    .patooCard()
                }
                
                // Quick Action Cards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hızlı İşlemler")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    HStack(spacing: 16) {
                        QuickActionCard(
                            title: "Video Dönüştür",
                            description: "MP4, MOV, MKV, WebM formatları arasında kayıpsız veya optimize dönüştürme.",
                            icon: "arrow.triangle.2.circlepath",
                            accentColor: PatooTheme.cyan
                        ) {
                            selectedSection = .convert
                        }
                        
                        QuickActionCard(
                            title: "Video Sıkıştır",
                            description: "Dosya boyutunu kalite kaybını minimumda tutarak güvenle küçültün.",
                            icon: "arrow.down.right.and.arrow.up.left",
                            accentColor: PatooTheme.violet
                        ) {
                            selectedSection = .compress
                        }
                        
                        QuickActionCard(
                            title: "Ses Çıkar",
                            description: "Videolardan sesi MP3, AAC veya kayıpsız FLAC/WAV formatında ayıklayın.",
                            icon: "waveform",
                            accentColor: PatooTheme.blue
                        ) {
                            selectedSection = .audioExtract
                        }
                    }
                }
                
                // Active Processing Job Banner (if running)
                if let active = queueManager.activeJob {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Şu Anda İşleniyor")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(PatooTheme.cyan)
                            Spacer()
                            Button("Kuyruğa Git") {
                                selectedSection = .queue
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PatooTheme.cyan)
                        }
                        
                        HStack(spacing: 16) {
                            HUDProgressRing(progress: active.progress, size: 52)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(active.fileName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(PatooTheme.textPrimary)
                                
                                if case .processing(_, let speed, let fps, let remaining) = active.status {
                                    HStack(spacing: 12) {
                                        Text("Hız: \(speed)")
                                        Text("FPS: \(fps)")
                                        if let rem = remaining {
                                            Text(rem)
                                        }
                                    }
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(PatooTheme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            PatooButton("İptal Et", style: .danger) {
                                queueManager.cancelJob(id: active.id)
                            }
                        }
                    }
                    .padding(16)
                    .patooCard()
                }
            }
            .padding(24)
        }
        .background(PatooTheme.bgDark)
    }
}

private struct QuickActionCard: View {
    let title: String
    let description: String
    let icon: String
    let accentColor: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(PatooTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(spacing: 4) {
                    Text("Başla")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                }
                .foregroundColor(accentColor)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .patooCard(isHovered: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

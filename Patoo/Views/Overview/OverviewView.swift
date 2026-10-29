//
//  OverviewView.swift
//  Patoo
//

import SwiftUI

public struct OverviewView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    @State private var droppedFile: URL? = nil
    @State private var isAnalyzing: Bool = false
    @State private var fileMetadata: MediaMetadata? = nil
    
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
                    
                    Text("Dosya ekleme, son işlemler, hızlı eylemler ve genel işlem durumu.")
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
                
                // Quick Actions (Empty by default, populated dynamically via user pin)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Hızlı Eylemler")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        if !appState.pinnedSections.isEmpty {
                            Text("\(appState.pinnedSections.count) Sabitlendi")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(PatooTheme.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(PatooTheme.cyan.opacity(0.15))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    if appState.pinnedSections.isEmpty {
                        // Empty state as requested by user
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(PatooTheme.cyan.opacity(0.08))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "pin")
                                    .font(.system(size: 18))
                                    .foregroundColor(PatooTheme.cyan.opacity(0.7))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Henüz Hızlı Eylem Sabitlenmedi")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(PatooTheme.textPrimary)
                                
                                Text("Diğer menülerin (Dönüştürme, Sıkıştırma, Ses Stüdyosu vb.) sağ üst köşesindeki 📌 butonuna tıklayarak sık kullandığınız eylemleri buraya sabitleyebilirsiniz.")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PatooTheme.bgCard)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                .foregroundColor(PatooTheme.borderSubtle)
                        )
                    } else {
                        // User-pinned actions grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 340), spacing: 14)], spacing: 14) {
                            ForEach(appState.pinnedSections) { section in
                                PinnedActionCard(
                                    section: section,
                                    onSelect: {
                                        selectedSection = section
                                    },
                                    onUnpin: {
                                        appState.togglePin(section)
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Quick Media Dropzone on Overview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hızlı Dosya Ekleme")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    if let file = droppedFile, let meta = fileMetadata {
                        VStack(alignment: .leading, spacing: 12) {
                            MediaInspectorView(metadata: meta) {
                                droppedFile = nil
                                fileMetadata = nil
                            }
                            
                            HStack(spacing: 12) {
                                Button("Dönüştürmeye Gönder") {
                                    selectedSection = .convert
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(PatooTheme.cyan)
                                .cornerRadius(6)
                                
                                Button("Sıkıştırmaya Gönder") {
                                    selectedSection = .compress
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(PatooTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(PatooTheme.bgCard)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                )
                                
                                Button("Ses Stüdyosuna Gönder") {
                                    selectedSection = .audioStudio
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(PatooTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(PatooTheme.bgCard)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                )
                                
                                Button("Ayrıntılı Medya Bilgisi") {
                                    selectedSection = .mediaInfo
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(PatooTheme.cyan)
                            }
                        }
                    } else {
                        FileDropZone(
                            title: "Bir Medya Dosyası Bırakın",
                            subtitle: "İşlem seçmek veya ayrıntılı analiz yapmak için dosyayı sürükleyin",
                            isAnalyzing: isAnalyzing,
                            onFileSelected: handleQuickDrop
                        )
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
    
    private func handleQuickDrop(_ url: URL) {
        droppedFile = url
        isAnalyzing = true
        
        Task {
            do {
                let meta = try await FFprobeService.shared.analyze(fileURL: url)
                self.fileMetadata = meta
                self.isAnalyzing = false
            } catch {
                self.isAnalyzing = false
                appState.showToast("Dosya analizi başarısız: \(error.localizedDescription)", isError: true)
            }
        }
    }
}

private struct PinnedActionCard: View {
    let section: NavigationSection
    let onSelect: () -> Void
    let onUnpin: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(PatooTheme.cyan.opacity(0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: section.iconName)
                            .font(.system(size: 15))
                            .foregroundColor(PatooTheme.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: onUnpin) {
                        Image(systemName: "pin.slash")
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.textTertiary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help("Hızlı Eylemlerden Kaldır")
                }
                
                Text(section.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(PatooTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Aç")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(PatooTheme.cyan)
                }
            }
            .padding(14)
            .background(isHovered ? PatooTheme.bgCardHover : PatooTheme.bgCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? PatooTheme.cyan.opacity(0.4) : PatooTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

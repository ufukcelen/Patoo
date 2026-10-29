//
//  CompressView.swift
//  Patoo
//

import SwiftUI

public struct CompressView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    @State private var selectedFileURL: URL? = nil
    @State private var metadata: MediaMetadata? = nil
    @State private var isAnalyzing: Bool = false
    @State private var config = CompressionConfig()
    @State private var outputDirectory: URL? = nil
    
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
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Video Sıkıştır")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Görsel kaliteyi korurken akıllı algoritmalarla dosya boyutunu küçültün.")
                        .font(.system(size: 13))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                
                // Dropzone or Inspector
                if let meta = metadata {
                    MediaInspectorView(metadata: meta) {
                        selectedFileURL = nil
                        metadata = nil
                    }
                } else {
                    FileDropZone(
                        title: "Sıkıştırılacak Video Dosyasını Ekleyin",
                        subtitle: "Büyük boyutlu video dosyalarını buraya bırakın",
                        isAnalyzing: isAnalyzing,
                        onFileSelected: analyzeFile
                    )
                }
                
                if let currentFile = selectedFileURL {
                    // Compression Profiles Cards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sıkıştırma Profili")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        VStack(spacing: 10) {
                            ForEach([CompressionProfile.small, .balanced, .highQuality, .custom]) { profile in
                                CompressionProfileCard(
                                    profile: profile,
                                    isSelected: config.profile == profile
                                ) {
                                    config.profile = profile
                                }
                            }
                        }
                    }
                    
                    // Fine tuning options card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Gelişmiş Seçenekler")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        // Downscale toggle
                        Toggle(isOn: $config.downscaleTo1080pIfLarger) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("4K / 2K Videoları 1080p Full HD'ye Ölçekle")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PatooTheme.textPrimary)
                                Text("Dosya boyutunu önemli ölçüde azaltır, ekranlarda kalite kaybı hissedilmez.")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textTertiary)
                            }
                        }
                        .toggleStyle(.checkbox)
                        
                        // Hardware Acceleration toggle
                        Toggle(isOn: $config.useHardwareAcceleration) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Silicon Donanım Hızlandırma (VideoToolbox)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PatooTheme.textPrimary)
                                Text("GPU ve Apple Media Engine kullanarak işlemi 5-10 kat daha hızlı tamamlar.")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textTertiary)
                            }
                        }
                        .toggleStyle(.checkbox)
                        
                        // Custom CRF slider
                        if config.profile == .custom {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Özel CRF Değeri")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(PatooTheme.textSecondary)
                                    Spacer()
                                    Text("\(config.customCRF)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(PatooTheme.cyan)
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(config.customCRF) },
                                    set: { config.customCRF = Int($0) }
                                ), in: 16...36, step: 1)
                                .tint(PatooTheme.cyan)
                            }
                        }
                        
                        Divider().background(PatooTheme.borderSubtle)
                        
                        // Output Destination
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kayıt Konumu")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                
                                Text(outputDirectory?.path ?? "Kaynak klasör ile aynı (\(currentFile.deletingLastPathComponent().lastPathComponent))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(PatooTheme.textTertiary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button("Klasör Değiştir") {
                                chooseOutputFolder()
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PatooTheme.cyan)
                        }
                    }
                    .padding(18)
                    .patooCard()
                    
                    // Action Button
                    HStack {
                        Spacer()
                        
                        PatooButton(
                            "Sıkıştırmayı Başlat",
                            icon: "arrow.down.right.and.arrow.up.left",
                            style: .primary
                        ) {
                            enqueueCompression(fileURL: currentFile)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(PatooTheme.bgDark)
    }
    
    private func analyzeFile(_ url: URL) {
        selectedFileURL = url
        isAnalyzing = true
        
        Task {
            do {
                let meta = try await FFprobeService.shared.analyze(fileURL: url)
                self.metadata = meta
                self.isAnalyzing = false
                appState.showToast("Medya analiz edildi: \(meta.formattedFileSize)")
            } catch {
                self.isAnalyzing = false
                appState.showToast("FFprobe hatası: \(error.localizedDescription)", isError: true)
            }
        }
    }
    
    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let dir = panel.url {
            outputDirectory = dir
        }
    }
    
    private func enqueueCompression(fileURL: URL) {
        let ext = fileURL.pathExtension.isEmpty ? "mp4" : fileURL.pathExtension
        let targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: fileURL,
            destinationDirectory: outputDirectory,
            suffix: "compressed",
            targetExtension: ext,
            overwrite: false
        )
        
        queueManager.enqueue(
            sourceURL: fileURL,
            sourceMetadata: metadata,
            targetURL: targetURL,
            type: .compress(config)
        )
        
        appState.showToast("Sıkıştırma işlemi kuyruğa eklendi")
        selectedSection = .queue
    }
}

private struct CompressionProfileCard: View {
    let profile: CompressionProfile
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? PatooTheme.cyan.opacity(0.2) : PatooTheme.bgInput)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: profile.iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? PatooTheme.cyan : PatooTheme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text(profile.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(PatooTheme.cyan)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? PatooTheme.cyan.opacity(0.08) : (isHovered ? PatooTheme.bgCardHover : PatooTheme.bgCard))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? PatooTheme.borderActive : PatooTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

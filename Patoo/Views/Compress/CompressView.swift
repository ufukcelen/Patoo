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
    @State private var customFileName: String = ""
    
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
                // Header with Pin Button
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sıkıştırma")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text("Kalite modu, hedef dosya boyutu, yaklaşık sonuç ve kalite karşılaştırması.")
                            .font(.system(size: 13))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    PatooPinButton(section: .compress, appState: appState)
                }
                
                // Dropzone or Inspector
                if let meta = metadata {
                    MediaInspectorView(metadata: meta) {
                        selectedFileURL = nil
                        metadata = nil
                        customFileName = ""
                    }
                } else {
                    FileDropZone(
                        title: "Sıkıştırılacak Video Dosyasını Ekleyin",
                        subtitle: "Büyük boyutlu MP4, MOV, MKV ve diğer video dosyaları",
                        isAnalyzing: isAnalyzing,
                        onFileSelected: analyzeFile
                    )
                }
                
                if let currentFile = selectedFileURL {
                    // Compression Options Card
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Sıkıştırma Profili & Kalite Modu")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        // Profile Cards Grid
                        HStack(spacing: 12) {
                            ForEach([CompressionProfile.small, .balanced, .highQuality, .custom]) { profile in
                                CompressionProfileCard(
                                    profile: profile,
                                    isSelected: config.profile == profile
                                ) {
                                    config.profile = profile
                                }
                            }
                        }
                        
                        Divider().background(PatooTheme.borderSubtle)
                        
                        // Size & Quality Estimation HUD
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Yaklaşık Sonuç & Kalite Karşılaştırması")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(PatooTheme.textPrimary)
                                
                                Spacer()
                                
                                Text(estimatedSavingBadge)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(PatooTheme.success)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(PatooTheme.success.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Orijinal Boyut")
                                        .font(.system(size: 10))
                                        .foregroundColor(PatooTheme.textTertiary)
                                    Text(metadata?.formattedFileSize ?? "Bilinmiyor")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(PatooTheme.textPrimary)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(PatooTheme.cyan)
                                    .font(.system(size: 12))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tahmini Çıktı Boyutu")
                                        .font(.system(size: 10))
                                        .foregroundColor(PatooTheme.textTertiary)
                                    Text(estimatedSizeText)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(PatooTheme.cyan)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Tahmini Tasarruf")
                                        .font(.system(size: 10))
                                        .foregroundColor(PatooTheme.textTertiary)
                                    Text(estimatedSavingText)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(PatooTheme.success)
                                }
                            }
                            .padding(12)
                            .background(PatooTheme.bgDark)
                            .cornerRadius(6)
                        }
                        
                        Divider().background(PatooTheme.borderSubtle)
                        
                        // Toggles
                        VStack(spacing: 12) {
                            // Hardware acceleration
                            Toggle(isOn: $config.useHardwareAcceleration) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Apple Silicon Donanım Hızlandırma (VideoToolbox)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(PatooTheme.textPrimary)
                                        
                                        Text("ÖNERİLEN")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(PatooTheme.cyan)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(PatooTheme.cyan.opacity(0.12))
                                            .cornerRadius(3)
                                    }
                                    
                                    Text("Apple M1/M2/M3/M4 GPU medya motorunu kullanarak ışık hızında sıkıştırır.")
                                        .font(.system(size: 11))
                                        .foregroundColor(PatooTheme.textTertiary)
                                }
                            }
                            .toggleStyle(.checkbox)
                            
                            // 1080p Downscale
                            Toggle(isOn: $config.downscaleTo1080pIfLarger) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Büyükse 1080p Full HD'ye Küçült")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(PatooTheme.textPrimary)
                                    
                                    Text("4K veya daha yüksek videoları maksimum 1920×1080 ölçeğine indirerek ekstra alan tasarrufu sağlar.")
                                        .font(.system(size: 11))
                                        .foregroundColor(PatooTheme.textTertiary)
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                        
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
                    }
                    .padding(18)
                    .patooCard()
                    
                    // Output File Name & Destination Card
                    OutputConfigView(
                        fileName: $customFileName,
                        targetExtension: currentFile.pathExtension.isEmpty ? "mp4" : currentFile.pathExtension,
                        outputDirectory: $outputDirectory,
                        sourceURL: currentFile,
                        defaultSuffix: "compressed"
                    )
                    
                    // Action Button
                    HStack {
                        Spacer()
                        
                        PatooButton(
                            "Sıkıştırmayı Başlat",
                            icon: "gauge.with.needle",
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
    
    private var estimatedSizeText: String {
        guard let originalBytes = metadata?.fileSize, originalBytes > 0 else {
            return "~%40-%70 Daha Küçük"
        }
        let ratio: Double
        switch config.profile {
        case .small: ratio = 0.35
        case .balanced: ratio = 0.55
        case .highQuality: ratio = 0.80
        case .custom:
            let factor = Double(config.customCRF - 16) / 20.0
            ratio = max(0.25, 0.90 - (factor * 0.65))
        }
        let estBytes = Int64(Double(originalBytes) * ratio)
        return ByteCountFormatter.string(fromByteCount: estBytes, countStyle: .file)
    }
    
    private var estimatedSavingText: String {
        switch config.profile {
        case .small: return "~%65 Tasarruf"
        case .balanced: return "~%45 Tasarruf"
        case .highQuality: return "~%20 Tasarruf"
        case .custom:
            let factor = Int((1.0 - (Double(config.customCRF - 16) / 20.0)) * 60)
            return "~%\(max(15, factor)) Tasarruf"
        }
    }
    
    private var estimatedSavingBadge: String {
        switch config.profile {
        case .small: return "ULTRA SIKIŞTIRMA"
        case .balanced: return "DENGELİ OPTİMUM"
        case .highQuality: return "YÜKSEK KALİTE"
        case .custom: return "ÖZEL CRF \(config.customCRF)"
        }
    }
    
    private func analyzeFile(_ url: URL) {
        selectedFileURL = url
        isAnalyzing = true
        customFileName = url.deletingPathExtension().lastPathComponent + "_compressed"
        
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
    
    private func enqueueCompression(fileURL: URL) {
        let ext = fileURL.pathExtension.isEmpty ? "mp4" : fileURL.pathExtension
        let targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: fileURL,
            destinationDirectory: outputDirectory,
            customFileName: customFileName.isEmpty ? nil : customFileName,
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(profile.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? PatooTheme.cyan : PatooTheme.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(PatooTheme.cyan)
                    }
                }
                
                Text(profile.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(PatooTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("~%20-%65 Boyut")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(PatooTheme.textTertiary)
                    Spacer()
                    Text("CRF \(profile.defaultCRF)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? PatooTheme.cyan : PatooTheme.textTertiary)
                }
            }
            .padding(12)
            .background(isSelected ? PatooTheme.cyan.opacity(0.08) : PatooTheme.bgCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? PatooTheme.cyan : PatooTheme.borderSubtle, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

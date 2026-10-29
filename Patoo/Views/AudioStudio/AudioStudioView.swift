//
//  AudioStudioView.swift
//  Patoo
//

import SwiftUI

public struct AudioStudioView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    @State private var selectedFileURL: URL? = nil
    @State private var metadata: MediaMetadata? = nil
    @State private var isAnalyzing: Bool = false
    @State private var config = AudioStudioConfig()
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
                        Text("Ses Stüdyosu")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text("Ses çıkarma, sesi kaldırma, normalizasyon, ses seviyesi ve fade efektleri.")
                            .font(.system(size: 13))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    PatooPinButton(section: .audioStudio, appState: appState)
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
                        title: "Ses Stüdyosuna Medya Dosyası Ekleyin",
                        subtitle: "MP4, MOV, MKV, MP3, WAV, FLAC veya diğer tüm medya formatları",
                        isAnalyzing: isAnalyzing,
                        onFileSelected: analyzeFile
                    )
                }
                
                if let currentFile = selectedFileURL {
                    // Studio Mode Picker
                    VStack(alignment: .leading, spacing: 14) {
                        Text("İşlem Modu")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Picker("", selection: $config.mode) {
                            ForEach(AudioStudioMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: config.mode) { _, newMode in
                            updateDefaultFileName(mode: newMode, fileURL: currentFile)
                        }
                        
                        Text(config.mode.subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    .padding(16)
                    .patooCard()
                    
                    // Specific Mode Options Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(config.mode.title) Ayarları")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        switch config.mode {
                        case .extract:
                            extractOptionsView
                        case .removeAudio:
                            removeAudioOptionsView
                        case .normalize:
                            normalizeOptionsView
                        case .volume:
                            volumeOptionsView
                        case .fade:
                            fadeOptionsView
                        }
                    }
                    .padding(18)
                    .patooCard()
                    
                    // Output Config
                    OutputConfigView(
                        fileName: $customFileName,
                        targetExtension: targetExtensionForCurrentMode(currentFile: currentFile),
                        outputDirectory: $outputDirectory,
                        sourceURL: currentFile,
                        defaultSuffix: suffixForMode(config.mode)
                    )
                    
                    // Action Button
                    HStack {
                        Spacer()
                        
                        PatooButton(
                            "İşlemi Başlat",
                            icon: config.mode.iconName,
                            style: .primary
                        ) {
                            enqueueStudioOperation(fileURL: currentFile)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(PatooTheme.bgDark)
    }
    
    // MARK: - Sub-views per mode
    private var extractOptionsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hedef Ses Formatı")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PatooTheme.textSecondary)
                
                Picker("", selection: $config.extractionConfig.format) {
                    ForEach(AudioExtractFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .labelsHidden()
            }
            
            if config.extractionConfig.format.supportsBitrateSelection {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ses Bit Hızı (Kalite)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(PatooTheme.textSecondary)
                    
                    Picker("", selection: $config.extractionConfig.bitrate) {
                        ForEach(AudioBitrate.allCases) { br in
                            Text(br.displayName).tag(br)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            Toggle(isOn: $config.extractionConfig.tryPassthroughIfCompatible) {
                Text("Uyumluysa Akışı Doğrudan Kopyala (Passthrough)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PatooTheme.textPrimary)
            }
            .toggleStyle(.checkbox)
        }
    }
    
    private var removeAudioOptionsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: 24))
                .foregroundColor(PatooTheme.warning)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Sessiz Video Çıktısı")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(PatooTheme.textPrimary)
                
                Text("Videodan ses akışı tamamen kaldırılacak. Video akışı doğrudan kopyalandığından işlem anında biter ve sıfır kalite kaybı yaşanır.")
                    .font(.system(size: 11))
                    .foregroundColor(PatooTheme.textSecondary)
            }
        }
        .padding(10)
    }
    
    private var normalizeOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hedef Ses Yüksekliği (EBU R128 LUFS)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PatooTheme.textSecondary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", config.targetLUFS)) LUFS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(PatooTheme.cyan)
            }
            
            Slider(value: $config.targetLUFS, in: -24.0...(-12.0), step: 0.5)
                .tint(PatooTheme.cyan)
            
            HStack(spacing: 8) {
                presetButton(title: "YouTube / Spotify (-14 LUFS)", value: -14.0)
                presetButton(title: "Podcast / Web (-16 LUFS)", value: -16.0)
                presetButton(title: "Televizyon / Yayın (-23 LUFS)", value: -23.0)
            }
        }
    }
    
    private var volumeOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ses Düzeyi Değişimi (Gain)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PatooTheme.textSecondary)
                
                Spacer()
                
                Text(config.volumeGainDB >= 0 ? "+\(String(format: "%.1f", config.volumeGainDB)) dB" : "\(String(format: "%.1f", config.volumeGainDB)) dB")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(config.volumeGainDB > 0 ? PatooTheme.cyan : (config.volumeGainDB < 0 ? PatooTheme.warning : PatooTheme.textPrimary))
            }
            
            Slider(value: $config.volumeGainDB, in: -18.0...18.0, step: 0.5)
                .tint(PatooTheme.cyan)
            
            HStack(spacing: 8) {
                presetVolumeButton(title: "-6 dB (Yarı Yarıya)", value: -6.0)
                presetVolumeButton(title: "0 dB (Değişimsiz)", value: 0.0)
                presetVolumeButton(title: "+3 dB (Hafif Yükselt)", value: 3.0)
                presetVolumeButton(title: "+6 dB (2 Kat Güçlü)", value: 6.0)
            }
        }
    }
    
    private var fadeOptionsView: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Fade-In (Açılış Yumuşatma Süresi)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(PatooTheme.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", config.fadeInDuration)) sn")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(PatooTheme.cyan)
                }
                Slider(value: $config.fadeInDuration, in: 0.0...10.0, step: 0.5)
                    .tint(PatooTheme.cyan)
            }
            
            Divider().background(PatooTheme.borderSubtle)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Fade-Out (Kapanış Yumuşatma Süresi)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(PatooTheme.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", config.fadeOutDuration)) sn")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(PatooTheme.cyan)
                }
                Slider(value: $config.fadeOutDuration, in: 0.0...10.0, step: 0.5)
                    .tint(PatooTheme.cyan)
            }
        }
    }
    
    private func presetButton(title: String, value: Double) -> some View {
        Button(title) {
            config.targetLUFS = value
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(abs(config.targetLUFS - value) < 0.1 ? PatooTheme.cyan.opacity(0.18) : PatooTheme.bgDark)
        .foregroundColor(abs(config.targetLUFS - value) < 0.1 ? PatooTheme.cyan : PatooTheme.textTertiary)
        .cornerRadius(4)
    }
    
    private func presetVolumeButton(title: String, value: Double) -> some View {
        Button(title) {
            config.volumeGainDB = value
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(abs(config.volumeGainDB - value) < 0.1 ? PatooTheme.cyan.opacity(0.18) : PatooTheme.bgDark)
        .foregroundColor(abs(config.volumeGainDB - value) < 0.1 ? PatooTheme.cyan : PatooTheme.textTertiary)
        .cornerRadius(4)
    }
    
    private func targetExtensionForCurrentMode(currentFile: URL) -> String {
        switch config.mode {
        case .extract:
            return config.extractionConfig.format.fileExtension
        case .removeAudio, .normalize, .volume, .fade:
            return currentFile.pathExtension.isEmpty ? "mp4" : currentFile.pathExtension
        }
    }
    
    private func suffixForMode(_ mode: AudioStudioMode) -> String {
        switch mode {
        case .extract: return "audio"
        case .removeAudio: return "muted"
        case .normalize: return "normalized"
        case .volume: return "boosted"
        case .fade: return "fade"
        }
    }
    
    private func updateDefaultFileName(mode: AudioStudioMode, fileURL: URL) {
        let base = fileURL.deletingPathExtension().lastPathComponent
        customFileName = "\(base)_\(suffixForMode(mode))"
    }
    
    private func analyzeFile(_ url: URL) {
        selectedFileURL = url
        isAnalyzing = true
        updateDefaultFileName(mode: config.mode, fileURL: url)
        
        Task {
            do {
                let meta = try await FFprobeService.shared.analyze(fileURL: url)
                self.metadata = meta
                self.isAnalyzing = false
                appState.showToast("Ses ve video akışları başarıyla analiz edildi")
            } catch {
                self.isAnalyzing = false
                appState.showToast("FFprobe hatası: \(error.localizedDescription)", isError: true)
            }
        }
    }
    
    private func enqueueStudioOperation(fileURL: URL) {
        let ext = targetExtensionForCurrentMode(currentFile: fileURL)
        let targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: fileURL,
            destinationDirectory: outputDirectory,
            customFileName: customFileName.isEmpty ? nil : customFileName,
            suffix: suffixForMode(config.mode),
            targetExtension: ext,
            overwrite: false
        )
        
        queueManager.enqueue(
            sourceURL: fileURL,
            sourceMetadata: metadata,
            targetURL: targetURL,
            type: .audioStudio(config)
        )
        
        appState.showToast("\(config.mode.title) işlemi kuyruğa eklendi")
        selectedSection = .queue
    }
}

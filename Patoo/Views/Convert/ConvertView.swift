//
//  ConvertView.swift
//  Patoo
//

import SwiftUI

public struct ConvertView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    @State private var selectedFileURL: URL? = nil
    @State private var metadata: MediaMetadata? = nil
    @State private var isAnalyzing: Bool = false
    @State private var config = ConversionConfig()
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
                    Text("Video Dönüştür")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Videonuzu popüler formatlara, çözünürlüklere ve gelişmiş kodeklere dönüştürün.")
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
                        title: "Dönüştürülecek Video Dosyasını Ekleyin",
                        subtitle: "MP4, MOV, MKV, WebM, AVI ve diğer tüm formatlar",
                        isAnalyzing: isAnalyzing,
                        onFileSelected: analyzeFile
                    )
                }
                
                if let currentFile = selectedFileURL {
                    // Settings Card
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Dönüştürme Seçenekleri")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        // Container & Video Codec
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hedef Format (Konteyner)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                
                                Picker("", selection: $config.container) {
                                    ForEach(ContainerFormat.allCases) { container in
                                        Text(container.displayName).tag(container)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: config.container) { _, newContainer in
                                    if !newContainer.supportedVideoCodecs.contains(config.videoCodec) {
                                        config.videoCodec = newContainer.defaultVideoCodec
                                    }
                                    if !newContainer.supportedAudioCodecs.contains(config.audioCodec) {
                                        config.audioCodec = newContainer.defaultAudioCodec
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Video Kodeki")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                
                                Picker("", selection: $config.videoCodec) {
                                    ForEach(config.container.supportedVideoCodecs) { codec in
                                        Text(codec.displayName).tag(codec)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                        
                        Divider().background(PatooTheme.borderSubtle)
                        
                        // Resolution & Framerate
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Çözünürlük")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                
                                Picker("", selection: $config.resolution) {
                                    ForEach(TargetResolution.allCases) { res in
                                        Text(res.displayName).tag(res)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Kare Hızı (FPS)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                
                                Picker("", selection: $config.frameRate) {
                                    ForEach(TargetFrameRate.allCases) { fps in
                                        Text(fps.displayName).tag(fps)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                        
                        Divider().background(PatooTheme.borderSubtle)
                        
                        // Audio Codec
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ses Kodeki")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(PatooTheme.textSecondary)
                            
                            Picker("", selection: $config.audioCodec) {
                                ForEach(config.container.supportedAudioCodecs) { audio in
                                    Text(audio.displayName).tag(audio)
                                }
                            }
                            .labelsHidden()
                        }
                        
                        // Quality Slider (CRF) when software encoder is selected
                        if config.videoCodec == .h264 || config.videoCodec == .h265 {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Kalite Faktörü (CRF)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(PatooTheme.textSecondary)
                                    Spacer()
                                    Text("\(config.crf) (Daha düşük = Daha yüksek kalite)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(PatooTheme.cyan)
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(config.crf) },
                                    set: { config.crf = Int($0) }
                                ), in: 15...32, step: 1)
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
                    
                    // Action Buttons
                    HStack {
                        Spacer()
                        
                        PatooButton(
                            "Kuyruğa Ekle ve Başlat",
                            icon: "arrow.triangle.2.circlepath",
                            style: .primary
                        ) {
                            enqueueConversion(fileURL: currentFile)
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
                appState.showToast("Medya başarıyla analiz edildi: \(meta.formattedDuration)")
            } catch {
                self.isAnalyzing = false
                appState.showToast("FFprobe analizi başarısız: \(error.localizedDescription)", isError: true)
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
    
    private func enqueueConversion(fileURL: URL) {
        let targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: fileURL,
            destinationDirectory: outputDirectory,
            suffix: "converted",
            targetExtension: config.container.rawValue,
            overwrite: false
        )
        
        queueManager.enqueue(
            sourceURL: fileURL,
            sourceMetadata: metadata,
            targetURL: targetURL,
            type: .convert(config)
        )
        
        appState.showToast("Dönüştürme işlemi kuyruğa eklendi")
        selectedSection = .queue
    }
}

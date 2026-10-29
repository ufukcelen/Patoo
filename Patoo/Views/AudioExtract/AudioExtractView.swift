//
//  AudioExtractView.swift
//  Patoo
//

import SwiftUI

public struct AudioExtractView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    @State private var selectedFileURL: URL? = nil
    @State private var metadata: MediaMetadata? = nil
    @State private var isAnalyzing: Bool = false
    @State private var config = AudioExtractionConfig()
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
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ses Çıkar")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Videolardan ses akışını ayırın, MP3, AAC, FLAC veya WAV olarak yüksek kalitede kaydedin.")
                        .font(.system(size: 13))
                        .foregroundColor(PatooTheme.textSecondary)
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
                        title: "Ses Çıkarılacak Video Dosyasını Ekleyin",
                        subtitle: "MP4, MOV, MKV, AVI, WebM ve diğer video formatları",
                        isAnalyzing: isAnalyzing,
                        onFileSelected: analyzeFile
                    )
                }
                
                if let currentFile = selectedFileURL {
                    // Audio Extraction Settings Card
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Ses Çıkarma Seçenekleri")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        // Format Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hedef Ses Formatı")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(PatooTheme.textSecondary)
                            
                            Picker("", selection: $config.format) {
                                ForEach(AudioExtractFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .labelsHidden()
                        }
                        
                        // Bitrate selector (if applicable)
                        if config.format.supportsBitrateSelection {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ses Bit Hızı (Kalite)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                
                                Picker("", selection: $config.bitrate) {
                                    ForEach(AudioBitrate.allCases) { br in
                                        Text(br.displayName).tag(br)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Stream copy passthrough toggle
                        Toggle(isOn: $config.tryPassthroughIfCompatible) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Uyumluysa Akışı Doğrudan Kopyala (Passthrough)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PatooTheme.textPrimary)
                                Text("Eğer kaynak ses formatı hedefle uyuşuyorsa yeniden kodlama yapmaz, sıfır kalite kaybıyla anında kaydeder.")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textTertiary)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                    .padding(18)
                    .patooCard()
                    
                    // Output File Name & Destination Card
                    OutputConfigView(
                        fileName: $customFileName,
                        targetExtension: config.format.fileExtension,
                        outputDirectory: $outputDirectory,
                        sourceURL: currentFile,
                        defaultSuffix: "audio"
                    )
                    
                    // Action Button
                    HStack {
                        Spacer()
                        
                        PatooButton(
                            "Sesi Çıkar ve Kaydet",
                            icon: "waveform",
                            style: .primary
                        ) {
                            enqueueAudioExtraction(fileURL: currentFile)
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
        customFileName = url.deletingPathExtension().lastPathComponent + "_audio"
        
        Task {
            do {
                let meta = try await FFprobeService.shared.analyze(fileURL: url)
                self.metadata = meta
                self.isAnalyzing = false
                appState.showToast("Medya analiz edildi: \(meta.formattedDuration)")
            } catch {
                self.isAnalyzing = false
                appState.showToast("FFprobe hatası: \(error.localizedDescription)", isError: true)
            }
        }
    }
    
    private func enqueueAudioExtraction(fileURL: URL) {
        let targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: fileURL,
            destinationDirectory: outputDirectory,
            customFileName: customFileName.isEmpty ? nil : customFileName,
            suffix: "audio",
            targetExtension: config.format.fileExtension,
            overwrite: false
        )
        
        queueManager.enqueue(
            sourceURL: fileURL,
            sourceMetadata: metadata,
            targetURL: targetURL,
            type: .extractAudio(config)
        )
        
        appState.showToast("Ses çıkarma işlemi kuyruğa eklendi")
        selectedSection = .queue
    }
}

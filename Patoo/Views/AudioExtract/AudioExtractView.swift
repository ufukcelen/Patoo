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
    
    public init(
        selectedSection: Binding<NavigationSection>,
        queueManager: QueueManager,
        appState: AppState
    ) {
        self._selectedSection = selectedSection
        self.queueManager = queueManager
        self.appState = appState
    }
    
    private var hasAudioStream: Bool {
        guard let meta = metadata else { return true }
        return !meta.audioStreams.isEmpty
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Videodan Ses Çıkar")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Video dosyalarındaki ses parçasını bağımsız yüksek kaliteli ses dosyalarına dönüştürün.")
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
                        title: "Ses Çıkarılacak Videoyu Ekleyin",
                        subtitle: "MP4, MOV, MKV veya diğer tüm video dosyaları",
                        isAnalyzing: isAnalyzing,
                        onFileSelected: analyzeFile
                    )
                }
                
                if let currentFile = selectedFileURL {
                    if !hasAudioStream {
                        // Warning banner for video without audio
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(PatooTheme.danger)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bu dosyada ses akışı bulunamadı")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(PatooTheme.textPrimary)
                                
                                Text("Seçtiğiniz video dosyasında ayrıştırılabilecek herhangi bir ses izi mevcut değildir. Lütfen ses içeren bir dosya seçin.")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textSecondary)
                            }
                        }
                        .padding(14)
                        .background(PatooTheme.danger.opacity(0.12))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PatooTheme.danger.opacity(0.3), lineWidth: 1)
                        )
                    } else {
                        // Options Card
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Ses Çıkarma Seçenekleri")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(PatooTheme.textPrimary)
                            
                            // Target format selector
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
                                "Sesi Çıkar ve Kaydet",
                                icon: "waveform",
                                style: .primary
                            ) {
                                enqueueAudioExtraction(fileURL: currentFile)
                            }
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
                appState.showToast("Medya analiz edildi: \(meta.formattedDuration)")
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
    
    private func enqueueAudioExtraction(fileURL: URL) {
        let targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: fileURL,
            destinationDirectory: outputDirectory,
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

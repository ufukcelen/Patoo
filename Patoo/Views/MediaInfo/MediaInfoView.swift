//
//  MediaInfoView.swift
//  Patoo
//

import SwiftUI
import AppKit

public struct MediaInfoView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    @State private var selectedFileURL: URL? = nil
    @State private var metadata: MediaMetadata? = nil
    @State private var rawJSON: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var showRawJSONSheet: Bool = false
    
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
                        Text("Medya Bilgisi")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text("Teknik özellikler, ses ve görüntü akışları, metadata ve ayrıntılı analiz.")
                            .font(.system(size: 13))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    PatooPinButton(section: .mediaInfo, appState: appState)
                }
                
                // File Drop Zone
                if selectedFileURL == nil {
                    FileDropZone(
                        title: "Analiz Edilecek Medya Dosyasını Ekleyin",
                        subtitle: "Tüm video, ses ve konteyner akışlarının ayrıntılı dökümünü çıkarın",
                        isAnalyzing: isAnalyzing,
                        onFileSelected: analyzeFile
                    )
                }
                
                if let file = selectedFileURL, let meta = metadata {
                    // Loaded file summary header bar
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(PatooTheme.cyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.lastPathComponent)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(PatooTheme.textPrimary)
                            
                            Text(file.path)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(PatooTheme.textTertiary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button("Farklı Dosya Seç") {
                            selectedFileURL = nil
                            metadata = nil
                            rawJSON = ""
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(PatooTheme.cyan)
                    }
                    .padding(14)
                    .background(PatooTheme.bgCard)
                    .cornerRadius(8)
                    
                    // Technical Overview HUD Cards
                    HStack(spacing: 12) {
                        hudMetricCard(title: "KONTEYNER", value: meta.containerFormat.uppercased(), icon: "shippingbox")
                        hudMetricCard(title: "DOSYA BOYUTU", value: meta.formattedFileSize, icon: "externaldrive")
                        hudMetricCard(title: "SÜRE", value: meta.formattedDuration, icon: "clock")
                        hudMetricCard(title: "GENEL BİT HIZI", value: meta.formattedBitrate, icon: "speedometer")
                    }
                    
                    // Video Streams Section
                    if !meta.videoStreams.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "film")
                                    .foregroundColor(PatooTheme.cyan)
                                Text("Görüntü Akışları (\(meta.videoStreams.count))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(PatooTheme.textPrimary)
                            }
                            
                            ForEach(meta.videoStreams) { vStream in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Akış #\(vStream.index): \(vStream.codec.uppercased())")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(PatooTheme.cyan)
                                        
                                        Spacer()
                                        
                                        Text(vStream.codecLongName ?? "")
                                            .font(.system(size: 11))
                                            .foregroundColor(PatooTheme.textTertiary)
                                    }
                                    
                                    HStack(spacing: 18) {
                                        specItem(label: "Çözünürlük", val: "\(vStream.width) × \(vStream.height)")
                                        specItem(label: "Kare Hızı", val: String(format: "%.2f fps", vStream.fps))
                                        specItem(label: "Piksel Formatı", val: vStream.pixelFormat ?? "yuv420p")
                                        if vStream.bitRate > 0 {
                                            specItem(label: "Bit Hızı", val: "\(vStream.bitRate / 1000) kbps")
                                        }
                                    }
                                }
                                .padding(14)
                                .background(PatooTheme.bgCard)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Audio Streams Section
                    if !meta.audioStreams.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(PatooTheme.violet)
                                Text("Ses Akışları (\(meta.audioStreams.count))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(PatooTheme.textPrimary)
                            }
                            
                            ForEach(meta.audioStreams) { aStream in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Akış #\(aStream.index): \(aStream.codec.uppercased())")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(PatooTheme.violet)
                                        
                                        Spacer()
                                        
                                        Text(aStream.codecLongName ?? "")
                                            .font(.system(size: 11))
                                            .foregroundColor(PatooTheme.textTertiary)
                                    }
                                    
                                    HStack(spacing: 18) {
                                        specItem(label: "Kanal Sayısı", val: "\(aStream.channels) Kanal (\(aStream.channelLayout ?? "Stereo"))")
                                        specItem(label: "Örnekleme Hızı", val: "\(aStream.sampleRate) Hz")
                                        if aStream.bitRate > 0 {
                                            specItem(label: "Bit Hızı", val: "\(aStream.bitRate / 1000) kbps")
                                        }
                                    }
                                }
                                .padding(14)
                                .background(PatooTheme.bgCard)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Action Shortcuts & Raw JSON Viewer
                    HStack(spacing: 12) {
                        Button(action: {
                            showRawJSONSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "curlybraces")
                                Text("Ham FFprobe JSON Dökümü")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(PatooTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(PatooTheme.bgCard)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Dönüştür") {
                            selectedSection = .convert
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PatooTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(PatooTheme.bgCard)
                        .cornerRadius(6)
                        
                        Button("Sıkıştır") {
                            selectedSection = .compress
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PatooTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(PatooTheme.bgCard)
                        .cornerRadius(6)
                        
                        Button("Ses Stüdyosu") {
                            selectedSection = .audioStudio
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(PatooTheme.cyan)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(24)
        }
        .background(PatooTheme.bgDark)
        .sheet(isPresented: $showRawJSONSheet) {
            rawJSONSheet
        }
    }
    
    private func hudMetricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(PatooTheme.cyan)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(PatooTheme.textTertiary)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(PatooTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PatooTheme.bgCard)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(PatooTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private func specItem(label: String, val: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(PatooTheme.textTertiary)
            Text(val)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(PatooTheme.textPrimary)
        }
    }
    
    private var rawJSONSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Ham FFprobe JSON Çıktısı")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(PatooTheme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(rawJSON, forType: .string)
                    appState.showToast("JSON panoya kopyalandı!")
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc")
                        Text("Panoya Kopyala")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(PatooTheme.cyan)
                }
                .buttonStyle(.plain)
                
                Button("Kapat") {
                    showRawJSONSheet = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(PatooTheme.textSecondary)
            }
            
            ScrollView {
                Text(rawJSON)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(PatooTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(PatooTheme.bgDark)
                    .cornerRadius(6)
            }
        }
        .padding(20)
        .frame(minWidth: 550, minHeight: 450)
        .background(PatooTheme.bgCard)
    }
    
    private func analyzeFile(_ url: URL) {
        selectedFileURL = url
        isAnalyzing = true
        
        Task {
            do {
                let (meta, json) = try await FFprobeService.shared.analyzeWithRawJSON(fileURL: url)
                self.metadata = meta
                self.rawJSON = json
                self.isAnalyzing = false
                appState.showToast("Ayrıntılı medya analizi tamamlandı")
            } catch {
                self.isAnalyzing = false
                appState.showToast("Analiz hatası: \(error.localizedDescription)", isError: true)
            }
        }
    }
}

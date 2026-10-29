//
//  BatchProcessView.swift
//  Patoo
//

import SwiftUI
import UniformTypeIdentifiers

public enum BatchActionType: String, CaseIterable, Identifiable {
    case convertMP4 = "convertMP4"
    case convertMKV = "convertMKV"
    case compressBalanced = "compressBalanced"
    case extractMP3 = "extractMP3"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .convertMP4: return "MP4 (H.264)"
        case .convertMKV: return "MKV (Matroska)"
        case .compressBalanced: return "Sıkıştırma (Dengeli)"
        case .extractMP3: return "Ses Çıkar (MP3 320k)"
        }
    }
    
    public var iconName: String {
        switch self {
        case .convertMP4, .convertMKV: return "arrow.triangle.2.circlepath"
        case .compressBalanced: return "gauge.with.needle"
        case .extractMP3: return "waveform"
        }
    }
}

public struct BatchItem: Identifiable, Equatable {
    public let id = UUID()
    public let fileURL: URL
    public var action: BatchActionType
    
    public var fileName: String {
        fileURL.lastPathComponent
    }
    
    public var fileSize: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? Int64 else {
            return "Bilinmiyor"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

public struct BatchProcessView: View {
    @Binding var selectedSection: NavigationSection
    var queueManager: QueueManager
    var appState: AppState
    
    @State private var batchItems: [BatchItem] = []
    @State private var globalAction: BatchActionType = .convertMP4
    @State private var outputDirectory: URL? = nil
    @State private var isTargetedForDrop = false
    
    private let supportedMediaExtensions = ["mp4", "mov", "mkv", "avi", "webm", "m4v", "flv", "mp3", "wav", "flac", "aac", "m4a"]
    
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
                        Text("Toplu İşlemler")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text("Klasör seçimi, dosya başına ayarlar, kuyruk, duraklatma ve iptal.")
                            .font(.system(size: 13))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    PatooPinButton(section: .batch, appState: appState)
                }
                
                // Add Files / Folder Selection Zone
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isTargetedForDrop ? PatooTheme.cyan : PatooTheme.borderSubtle,
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                            .background(isTargetedForDrop ? PatooTheme.cyan.opacity(0.06) : PatooTheme.bgCard)
                            .cornerRadius(10)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(PatooTheme.cyan)
                            
                            VStack(spacing: 4) {
                                Text("Klasör veya Birden Fazla Medya Dosyası Ekleyin")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(PatooTheme.textPrimary)
                                
                                Text("İçindeki tüm video ve ses dosyaları otomatik olarak listelenir.")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textSecondary)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: selectFolder) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder")
                                        Text("Klasör Seç...")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PatooTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(PatooTheme.bgDark)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: selectMultipleFiles) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Dosyaları Seç...")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PatooTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(PatooTheme.bgDark)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(24)
                    }
                    .frame(minHeight: 140)
                    .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                        handleDrop(providers)
                    }
                }
                
                // If items are loaded
                if !batchItems.isEmpty {
                    // Global Controls Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Toplu İşlem Yapılandırması")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(PatooTheme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(batchItems.count) Dosya")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(PatooTheme.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(PatooTheme.cyan.opacity(0.12))
                                .cornerRadius(4)
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Tüm Dosyalar İçin Varsayılan Eylem:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                
                                Picker("", selection: $globalAction) {
                                    ForEach(BatchActionType.allCases) { action in
                                        Text(action.title).tag(action)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: globalAction) { _, newAction in
                                    for i in 0..<batchItems.count {
                                        batchItems[i].action = newAction
                                    }
                                }
                            }
                        }
                        
                        Divider().background(PatooTheme.borderSubtle)
                        
                        // Output directory selector
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hedef Klasör")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(PatooTheme.textSecondary)
                                Text(outputDirectory?.path ?? "Kaynak dosya ile aynı dizin")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(PatooTheme.textPrimary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button("Değiştir...") {
                                chooseOutputDirectory()
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.cyan)
                        }
                    }
                    .padding(16)
                    .patooCard()
                    
                    // Batch Files List with Per-File Settings
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("İşlem Listesi (Dosya Başına Ayarlar)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PatooTheme.textPrimary)
                            
                            Spacer()
                            
                            Button("Listeyi Temizle") {
                                batchItems.removeAll()
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.danger)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach($batchItems) { $item in
                                HStack(spacing: 12) {
                                    Image(systemName: item.action.iconName)
                                        .font(.system(size: 14))
                                        .foregroundColor(PatooTheme.cyan)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.fileName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(PatooTheme.textPrimary)
                                            .lineLimit(1)
                                        
                                        Text(item.fileSize)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(PatooTheme.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Per-file action picker
                                    Picker("", selection: $item.action) {
                                        ForEach(BatchActionType.allCases) { action in
                                            Text(action.title).tag(action)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 170)
                                    
                                    // Remove single item button
                                    Button(action: {
                                        batchItems.removeAll(where: { $0.id == item.id })
                                    }) {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 13))
                                            .foregroundColor(PatooTheme.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(10)
                                .background(PatooTheme.bgCard)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Queue, Pause, Cancel Action Controls
                    HStack(spacing: 12) {
                        // Pause / Resume Queue toggle
                        Button(action: {
                            if queueManager.isPaused {
                                queueManager.resumeQueue()
                                appState.showToast("Kuyruk işlemeye devam ediyor")
                            } else {
                                queueManager.pauseQueue()
                                appState.showToast("Kuyruk duraklatıldı")
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: queueManager.isPaused ? "play.fill" : "pause.fill")
                                Text(queueManager.isPaused ? "Kuyruğu Devam Ettir" : "Kuyruğu Duraklat")
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
                        
                        // Cancel All
                        Button(action: {
                            queueManager.cancelAll()
                            appState.showToast("Tüm işlemler iptal edildi", isError: true)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.octagon")
                                Text("Tümünü İptal Et")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(PatooTheme.danger)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(PatooTheme.bgCard)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(PatooTheme.danger.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Enqueue All
                        PatooButton(
                            "Tümünü Kuyruğa Ekle (\(batchItems.count))",
                            icon: "square.stack.3d.up",
                            style: .primary
                        ) {
                            enqueueAllBatchItems()
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(PatooTheme.bgDark)
    }
    
    // MARK: - Actions
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Klasörü Seç"
        
        if panel.runModal() == .OK, let folderURL = panel.url {
            scanDirectory(folderURL)
        }
    }
    
    private func selectMultipleFiles() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Dosyaları Ekle"
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                addFileIfSupported(url)
            }
        }
    }
    
    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Hedef Klasörü Seç"
        
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url
        }
    }
    
    private func scanDirectory(_ folderURL: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return
        }
        
        var count = 0
        for case let fileURL as URL in enumerator {
            if addFileIfSupported(fileURL) {
                count += 1
            }
        }
        appState.showToast("\(count) medya dosyası eklendi")
    }
    
    @discardableResult
    private func addFileIfSupported(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if supportedMediaExtensions.contains(ext) {
            if !batchItems.contains(where: { $0.fileURL.path == url.path }) {
                batchItems.append(BatchItem(fileURL: url, action: globalAction))
                return true
            }
        }
        return false
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task { @MainActor in
                        var isDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                            scanDirectory(url)
                        } else {
                            addFileIfSupported(url)
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func enqueueAllBatchItems() {
        guard !batchItems.isEmpty else { return }
        
        for item in batchItems {
            let targetURL: URL
            let jobType: JobType
            
            switch item.action {
            case .convertMP4:
                var config = ConversionConfig()
                config.container = .mp4
                config.videoCodec = .h264Hardware
                config.audioCodec = .aac
                targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
                    sourceURL: item.fileURL,
                    destinationDirectory: outputDirectory,
                    suffix: "converted",
                    targetExtension: "mp4"
                )
                jobType = .convert(config)
                
            case .convertMKV:
                var config = ConversionConfig()
                config.container = .mkv
                config.videoCodec = .h264
                config.audioCodec = .aac
                targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
                    sourceURL: item.fileURL,
                    destinationDirectory: outputDirectory,
                    suffix: "converted",
                    targetExtension: "mkv"
                )
                jobType = .convert(config)
                
            case .compressBalanced:
                var config = CompressionConfig()
                config.profile = .balanced
                config.useHardwareAcceleration = true
                let ext = item.fileURL.pathExtension.isEmpty ? "mp4" : item.fileURL.pathExtension
                targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
                    sourceURL: item.fileURL,
                    destinationDirectory: outputDirectory,
                    suffix: "compressed",
                    targetExtension: ext
                )
                jobType = .compress(config)
                
            case .extractMP3:
                var config = AudioExtractionConfig()
                config.format = .mp3
                config.bitrate = .kbps320
                targetURL = FFmpegCommandBuilder.generateSafeTargetURL(
                    sourceURL: item.fileURL,
                    destinationDirectory: outputDirectory,
                    suffix: "audio",
                    targetExtension: "mp3"
                )
                jobType = .extractAudio(config)
            }
            
            queueManager.enqueue(
                sourceURL: item.fileURL,
                sourceMetadata: nil,
                targetURL: targetURL,
                type: jobType
            )
        }
        
        let count = batchItems.count
        batchItems.removeAll()
        appState.showToast("\(count) görev kuyruğa eklendi")
        selectedSection = .queue
    }
}

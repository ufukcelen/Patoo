//
//  FileDropZone.swift
//  Patoo
//

import SwiftUI
import UniformTypeIdentifiers

public struct FileDropZone: View {
    public let title: String
    public let subtitle: String
    public var isAnalyzing: Bool = false
    public let onFileSelected: (URL) -> Void
    
    @State private var isTargeted: Bool = false
    
    public init(
        title: String = "Medya Dosyasını Buraya Sürükleyin",
        subtitle: String = "MP4, MOV, MKV, WebM, MP3, WAV veya ses/video dosyaları",
        isAnalyzing: Bool = false,
        onFileSelected: @escaping (URL) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isAnalyzing = isAnalyzing
        self.onFileSelected = onFileSelected
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            if isAnalyzing {
                ProgressView()
                    .controlSize(.large)
                    .tint(PatooTheme.cyan)
                
                Text("FFprobe ile dosya analiz ediliyor...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(PatooTheme.cyan)
            } else {
                ZStack {
                    Circle()
                        .fill(isTargeted ? PatooTheme.cyan.opacity(0.18) : PatooTheme.cyan.opacity(0.08))
                        .frame(width: 58, height: 58)
                    
                    Image(systemName: isTargeted ? "arrow.down.doc.fill" : "arrow.down.doc")
                        .font(.system(size: 26))
                        .foregroundColor(PatooTheme.cyan)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(PatooTheme.textTertiary)
                }
                
                Button(action: openFileDialog) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                        Text("Dosya Seç")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(PatooTheme.bgInput)
                    .foregroundColor(PatooTheme.textPrimary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? PatooTheme.bgCardHover : PatooTheme.bgCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isTargeted ? PatooTheme.cyan : PatooTheme.borderSubtle,
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [6, 4])
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let fileURL = url else { return }
                DispatchQueue.main.async {
                    onFileSelected(fileURL)
                }
            }
            return true
        }
    }
    
    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        
        panel.allowedContentTypes = [
            .movie,
            .video,
            .audio,
            .mpeg4Movie,
            .quickTimeMovie,
            UTType(filenameExtension: "mkv") ?? .movie,
            UTType(filenameExtension: "webm") ?? .movie
        ]
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            onFileSelected(selectedURL)
        }
    }
}

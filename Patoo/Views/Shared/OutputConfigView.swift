//
//  OutputConfigView.swift
//  Patoo
//

import SwiftUI

public struct OutputConfigView: View {
    @Binding var fileName: String
    let targetExtension: String
    @Binding var outputDirectory: URL?
    let sourceURL: URL
    let defaultSuffix: String
    
    public init(
        fileName: Binding<String>,
        targetExtension: String,
        outputDirectory: Binding<URL?>,
        sourceURL: URL,
        defaultSuffix: String = "converted"
    ) {
        self._fileName = fileName
        self.targetExtension = targetExtension.replacingOccurrences(of: ".", with: "")
        self._outputDirectory = outputDirectory
        self.sourceURL = sourceURL
        self.defaultSuffix = defaultSuffix
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Çıktı Dosyası & Konumu")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(PatooTheme.textPrimary)
                
                Spacer()
                
                Button(action: resetToDefault) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                        Text("Varsayılana Dön")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(PatooTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            // Filename input row
            VStack(alignment: .leading, spacing: 6) {
                Text("Dosya Adı")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(PatooTheme.textSecondary)
                
                HStack(spacing: 6) {
                    TextField("Örn: yeni_video", text: $fileName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(PatooTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(PatooTheme.bgDark)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                        )
                    
                    Text(".\(targetExtension)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(PatooTheme.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .background(PatooTheme.cyan.opacity(0.12))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(PatooTheme.cyan.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            // Directory row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kayıt Klasörü")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PatooTheme.textSecondary)
                    
                    Text(displayPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(PatooTheme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button("Klasör Değiştir") {
                    chooseFolder()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(PatooTheme.cyan)
            }
        }
        .padding(14)
        .background(PatooTheme.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PatooTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private var displayPath: String {
        if let dir = outputDirectory {
            return dir.path
        }
        let folderName = sourceURL.deletingLastPathComponent().lastPathComponent
        return "Kaynak Klasör (\(folderName))"
    }
    
    private func resetToDefault() {
        let base = sourceURL.deletingPathExtension().lastPathComponent
        fileName = "\(base)_\(defaultSuffix)"
    }
    
    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let dir = panel.url {
            outputDirectory = dir
        }
    }
}

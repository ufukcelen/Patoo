//
//  SettingsView.swift
//  Patoo
//

import SwiftUI

public struct SettingsView: View {
    var appState: AppState
    var updateManager: AppUpdateManager
    
    @AppStorage("custom_ffmpeg_path") private var customFFmpegPath: String = ""
    @AppStorage("custom_ffprobe_path") private var customFFprobePath: String = ""
    @AppStorage("default_overwrite_files") private var overwriteFiles: Bool = false
    @AppStorage("default_use_videotoolbox") private var useVideoToolbox: Bool = true
    
    public init(appState: AppState, updateManager: AppUpdateManager = .shared) {
        self.appState = appState
        self.updateManager = updateManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ayarlar")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("FFmpeg altyapısı, donanım optimizasyonları ve güncelleme tercihleri.")
                        .font(.system(size: 13))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                
                // App & Updates Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Patoo Sürümü & Güncellemeler")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    HStack(spacing: 16) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text("Patoo Media Converter")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(PatooTheme.textPrimary)
                                
                                Text("v\(AppUpdateManager.currentVersion)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(PatooTheme.cyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(PatooTheme.cyan.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            
                            Text("Apple Silicon ve Intel için yüksek performanslı medya aracı.")
                                .font(.system(size: 11))
                                .foregroundColor(PatooTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button("Yenilikleri Gör") {
                                updateManager.showWhatsNewModal = true
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PatooTheme.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(PatooTheme.bgInput)
                            .cornerRadius(6)
                            
                            Button(action: {
                                updateManager.checkForUpdates(showFeedbackIfUpToDate: true)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Güncellemeleri Denetle")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(PatooTheme.cyan)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
                .patooCard()
                
                // FFmpeg Engine Status Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("FFmpeg & FFprobe Altyapısı")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Spacer()
                        
                        Button("Konumları Yeniden Tara") {
                            appState.refreshInstallation()
                            appState.showToast("FFmpeg konumları yeniden tarandı")
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(PatooTheme.cyan)
                    }
                    
                    // Engine Card
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(appState.ffmpegInstallation.isReady ? PatooTheme.success.opacity(0.15) : PatooTheme.warning.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: appState.ffmpegInstallation.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(appState.ffmpegInstallation.isReady ? PatooTheme.success : PatooTheme.warning)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.ffmpegInstallation.isReady ? "FFmpeg ve FFprobe Kurulu ve Aktif" : "FFmpeg Bulunamadı")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(PatooTheme.textPrimary)
                            
                            if let ver = appState.ffmpegInstallation.version {
                                Text(ver)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(PatooTheme.cyan)
                                    .lineLimit(1)
                            }
                            
                            if let ffmpeg = appState.ffmpegInstallation.ffmpegURL {
                                Text("Konum: \(ffmpeg.path)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(PatooTheme.textTertiary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .patooCard()
                    
                    if !appState.ffmpegInstallation.isReady {
                        // Installation guidance
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FFmpeg Nasıl Kurulur?")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(PatooTheme.textPrimary)
                            
                            Text("Terminal uygulamasını açarak Homebrew ile saniyeler içinde FFmpeg kurabilirsiniz:")
                                .font(.system(size: 12))
                                .foregroundColor(PatooTheme.textSecondary)
                            
                            HStack {
                                Text("brew install ffmpeg")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(PatooTheme.cyan)
                                
                                Spacer()
                                
                                Button("Komutu Kopyala") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("brew install ffmpeg", forType: .string)
                                    appState.showToast("Komut panoya kopyalandı")
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(PatooTheme.cyan)
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(6)
                        }
                        .padding(14)
                        .background(PatooTheme.warning.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PatooTheme.warning.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Custom Path Inputs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Özel Çalıştırılabilir Dosya Yolu (İsteğe Bağlı)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(PatooTheme.textSecondary)
                        
                        HStack {
                            TextField("/opt/homebrew/bin/ffmpeg", text: $customFFmpegPath)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                                .padding(8)
                                .background(PatooTheme.bgInput)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                                )
                            
                            Button("Gözat") {
                                browseBinary(forFFmpeg: true)
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PatooTheme.cyan)
                        }
                    }
                }
                .padding(18)
                .patooCard()
                
                // Hardware & Performance
                VStack(alignment: .leading, spacing: 16) {
                    Text("Donanım & Performans")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Toggle(isOn: $useVideoToolbox) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Varsayılan Olarak Apple Silicon Donanım Hızlandırma Kullan")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(PatooTheme.textPrimary)
                            Text("Apple Media Engine ve VideoToolbox ile ultra hızlı H.264 & HEVC kodlama sağlar.")
                                .font(.system(size: 11))
                                .foregroundColor(PatooTheme.textTertiary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    
                    Divider().background(PatooTheme.borderSubtle)
                    
                    Toggle(isOn: $overwriteFiles) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mevcut Dosyaların Üzerine Yaz")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(PatooTheme.textPrimary)
                            Text("Kapalıyken aynı isimde dosya varsa otomatik olarak _converted_1 şeklinde yeniden adlandırılır.")
                                .font(.system(size: 11))
                                .foregroundColor(PatooTheme.textTertiary)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                .padding(18)
                .patooCard()
            }
            .padding(24)
        }
        .background(PatooTheme.bgDark)
    }
    
    private func browseBinary(forFFmpeg: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if forFFmpeg {
                customFFmpegPath = url.path
            } else {
                customFFprobePath = url.path
            }
            FFmpegLocator.shared.saveCustomPaths(ffmpegPath: customFFmpegPath, ffprobePath: customFFprobePath)
            appState.refreshInstallation()
        }
    }
}

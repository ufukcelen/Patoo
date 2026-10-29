//
//  SettingsView.swift
//  Patoo
//

import SwiftUI

public struct SettingsView: View {
    var appState: AppState
    var updateManager: AppUpdateManager
    var ffmpegManager: FFmpegUpdateManager
    var themeManager: ThemeManager
    
    @AppStorage("custom_ffmpeg_path") private var customFFmpegPath: String = ""
    @AppStorage("custom_ffprobe_path") private var customFFprobePath: String = ""
    @AppStorage("default_overwrite_files") private var overwriteFiles: Bool = false
    @AppStorage("default_use_videotoolbox") private var useVideoToolbox: Bool = true
    
    public init(
        appState: AppState,
        updateManager: AppUpdateManager = .shared,
        ffmpegManager: FFmpegUpdateManager = .shared,
        themeManager: ThemeManager = .shared
    ) {
        self.appState = appState
        self.updateManager = updateManager
        self.ffmpegManager = ffmpegManager
        self.themeManager = themeManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ayarlar")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Görünüm temaları, FFmpeg altyapısı ve donanım optimizasyonları.")
                        .font(.system(size: 13))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                
                // App & Updates Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Patoo Sürümü & Güncellemeler")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "0E1522"))
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "00D2FF").opacity(0.45), lineWidth: 1.5)
                                )
                            
                            Image("MainLogo")
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Circle())
                                .padding(3)
                        }
                        .frame(width: 44, height: 44)
                        
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
                
                // MARK: - Temalar (Görünüm Seçenekleri)
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Temalar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Text("Patoo arayüzünün renk paletini ve görsel derinliğini özelleştirin.")
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(AppTheme.allCases) { theme in
                            ThemeSelectionCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    themeManager.currentTheme = theme
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .patooCard()
                
                // FFmpeg Engine Status & Auto-Updater Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("FFmpeg & FFprobe Altyapısı")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PatooTheme.textPrimary)
                        
                        Spacer()
                        
                        Button("Konumları Yeniden Tara") {
                            appState.refreshInstallation()
                            Task {
                                await ffmpegManager.checkForUpdates(appState: appState, silent: false)
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(PatooTheme.cyan)
                    }
                    
                    // Engine Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(statusBgColor)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: statusIconName)
                                    .font(.system(size: 20))
                                    .foregroundColor(statusFgColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(engineTitleText)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(PatooTheme.textPrimary)
                                    
                                    if appState.ffmpegInstallation.isReady {
                                        Text(appState.ffmpegInstallation.source.rawValue)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(PatooTheme.cyan)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(PatooTheme.cyan.opacity(0.12))
                                            .cornerRadius(4)
                                    }
                                }
                                
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
                            
                            // Action Button on Card
                            engineActionButton
                        }
                        
                        // Active Download Progress Bar
                        if case .downloading(let progress, let msg) = ffmpegManager.status {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(msg)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(PatooTheme.cyan)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(PatooTheme.cyan)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(PatooTheme.bgInput)
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(PatooTheme.cyan)
                                            .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(14)
                    .patooCard()
                    
                    // Standalone Auto-Download Recommendation Card (when missing)
                    if !appState.ffmpegInstallation.isReady {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(PatooTheme.cyan)
                                Text("Otomatik FFmpeg Kurulumu (Önerilen)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(PatooTheme.textPrimary)
                            }
                            
                            Text("Terminal veya Homebrew ile uğraşmadan, resmi ve kararlı en son FFmpeg & FFprobe binary'lerini tek tıkla Patoo'nun kendi güvenli alanına kurabilirsiniz.")
                                .font(.system(size: 12))
                                .foregroundColor(PatooTheme.textSecondary)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    ffmpegManager.performInstallOrUpdate(appState: appState)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Tek Tıkla FFmpeg İndir ve Kur")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(PatooTheme.cyan)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .disabled(ffmpegManager.status.isUpdating)
                                
                                Spacer()
                            }
                        }
                        .padding(14)
                        .background(PatooTheme.cyan.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PatooTheme.cyan.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Alternative Homebrew guidance
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alternatif: Terminal / Homebrew ile Kurulum")
                                .font(.system(size: 12, weight: .bold))
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
                        .padding(12)
                        .background(PatooTheme.bgCard)
                        .cornerRadius(8)
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
                            
                            Button("Seç...") {
                                selectFile { url in
                                    customFFmpegPath = url.path
                                    saveCustomPaths()
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 12))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PatooTheme.bgCard)
                            .cornerRadius(6)
                        }
                        
                        HStack {
                            TextField("/opt/homebrew/bin/ffprobe", text: $customFFprobePath)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                                .padding(8)
                                .background(PatooTheme.bgInput)
                                .cornerRadius(6)
                            
                            Button("Seç...") {
                                selectFile { url in
                                    customFFprobePath = url.path
                                    saveCustomPaths()
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 12))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PatooTheme.bgCard)
                            .cornerRadius(6)
                        }
                        
                        if !customFFmpegPath.isEmpty || !customFFprobePath.isEmpty {
                            Button("Özel Yolları Temizle ve Otomatiğe Dön") {
                                customFFmpegPath = ""
                                customFFprobePath = ""
                                saveCustomPaths()
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(PatooTheme.danger)
                        }
                    }
                    .padding(14)
                    .patooCard()
                }
                
                // General Behavior Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Genel Tercihler")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    VStack(spacing: 12) {
                        Toggle(isOn: $overwriteFiles) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aynı İsimli Dosyaların Üzerine Yaz")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(PatooTheme.textPrimary)
                                Text("Kapalıysa çıktı dosyasının sonuna otomatik numara eklenir (_1, _2)")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textSecondary)
                            }
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        
                        Divider().background(PatooTheme.borderSubtle)
                        
                        Toggle(isOn: $useVideoToolbox) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Silicon Donanım Hızlandırmasını (VideoToolbox) Önceliklendir")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(PatooTheme.textPrimary)
                                Text("H.264 ve HEVC çıktılarında M-serisi çiplerin donanım encoder'larını kullanır")
                                    .font(.system(size: 11))
                                    .foregroundColor(PatooTheme.textSecondary)
                            }
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    }
                }
                .padding(18)
                .patooCard()
            }
            .padding(24)
        }
        .background(PatooTheme.bgDark)
    }
    
    // MARK: - Subviews & Dynamic Computations
    @ViewBuilder
    private var engineActionButton: some View {
        switch ffmpegManager.status {
        case .updateAvailable(_, let latest):
            Button(action: {
                ffmpegManager.performInstallOrUpdate(appState: appState)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("FFmpeg Güncelle (v\(latest))")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(PatooTheme.warning)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
        case .notInstalled:
            Button(action: {
                ffmpegManager.performInstallOrUpdate(appState: appState)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.to.line")
                    Text("Tek Tıkla Kur")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(PatooTheme.cyan)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
        case .downloading:
            ProgressView()
                .scaleEffect(0.8)
                .padding(.horizontal, 12)
            
        case .checking, .upToDate, .error:
            Button(action: {
                Task {
                    await ffmpegManager.checkForUpdates(appState: appState, silent: false)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Güncellemeyi Denetle")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(PatooTheme.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(PatooTheme.bgInput)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var statusIconName: String {
        switch ffmpegManager.status {
        case .updateAvailable:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .notInstalled, .error:
            return "exclamationmark.triangle.fill"
        case .downloading:
            return "arrow.down.circle.fill"
        default:
            return appState.ffmpegInstallation.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        }
    }
    
    private var statusBgColor: Color {
        switch ffmpegManager.status {
        case .updateAvailable:
            return PatooTheme.warning.opacity(0.15)
        case .notInstalled, .error:
            return PatooTheme.danger.opacity(0.15)
        case .downloading:
            return PatooTheme.cyan.opacity(0.15)
        default:
            return appState.ffmpegInstallation.isReady ? PatooTheme.success.opacity(0.15) : PatooTheme.danger.opacity(0.15)
        }
    }
    
    private var statusFgColor: Color {
        switch ffmpegManager.status {
        case .updateAvailable:
            return PatooTheme.warning
        case .notInstalled, .error:
            return PatooTheme.danger
        case .downloading:
            return PatooTheme.cyan
        default:
            return appState.ffmpegInstallation.isReady ? PatooTheme.success : PatooTheme.danger
        }
    }
    
    private var engineTitleText: String {
        switch ffmpegManager.status {
        case .updateAvailable:
            return "FFmpeg Güncellemesi Mevcut"
        case .notInstalled:
            return "FFmpeg Bulunamadı"
        case .downloading:
            return "FFmpeg İndiriliyor..."
        case .error(let msg):
            return "Hata: \(msg)"
        default:
            return appState.ffmpegInstallation.isReady ? "FFmpeg ve FFprobe Kurulu ve Aktif" : "FFmpeg Bulunamadı"
        }
    }
    
    private func saveCustomPaths() {
        FFmpegLocator.shared.saveCustomPaths(
            ffmpegPath: customFFmpegPath.isEmpty ? nil : customFFmpegPath,
            ffprobePath: customFFprobePath.isEmpty ? nil : customFFprobePath
        )
        appState.refreshInstallation()
    }
    
    private func selectFile(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            completion(url)
        }
    }
}

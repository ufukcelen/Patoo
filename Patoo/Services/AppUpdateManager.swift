//
//  AppUpdateManager.swift
//  Patoo
//

import Foundation
import SwiftUI
import Observation

public enum UpdateStatus: Equatable, Sendable {
    case idle
    case checking
    case upToDate
    case updateAvailable(version: String, notes: String, url: URL?)
    case updating(progress: Double, message: String)
    case updated(message: String)
    case error(String)
}

public struct ReleaseChangelog: Identifiable, Sendable {
    public let id = UUID()
    public let version: String
    public let releaseDate: String
    public let title: String
    public let features: [FeatureItem]
    
    public struct FeatureItem: Identifiable, Sendable {
        public let id = UUID()
        public let icon: String
        public let title: String
        public let description: String
        public let badge: String?
        
        public init(icon: String, title: String, description: String, badge: String? = nil) {
            self.icon = icon
            self.title = title
            self.description = description
            self.badge = badge
        }
    }
}

@Observable
@MainActor
public final class AppUpdateManager {
    public static let shared = AppUpdateManager()
    
    public static let currentVersion: String = "0.0.3"
    public static let repoOwner: String = "ufukcelen"
    public static let repoName: String = "Patoo"
    public static let repoURL = URL(string: "https://github.com/ufukcelen/Patoo")!
    
    public var status: UpdateStatus = .idle
    public var showUpdateModal: Bool = false
    public var showWhatsNewModal: Bool = false
    
    private let userDefaultsKey = "patoo_last_seen_version"
    
    public init() {
        checkFirstLaunchForVersion()
    }
    
    // MARK: - What's New 1-Time Presentation
    public func checkFirstLaunchForVersion() {
        let lastSeen = UserDefaults.standard.string(forKey: userDefaultsKey)
        if lastSeen != Self.currentVersion {
            // New version detected! Show What's New modal once
            self.showWhatsNewModal = true
        }
    }
    
    public func markVersionAsSeen() {
        UserDefaults.standard.set(Self.currentVersion, forKey: userDefaultsKey)
        self.showWhatsNewModal = false
    }
    
    // MARK: - Current Version Changelog
    public var currentChangelog: ReleaseChangelog {
        ReleaseChangelog(
            version: "v0.0.3",
            releaseDate: "Ekim 2026",
            title: "Özel Çıktı İsimleri & QuickTime Motoru",
            features: [
                .init(
                    icon: "pencil.and.outline",
                    title: "Özel Çıktı Dosya Adı",
                    description: "Dönüştürme, sıkıştırma veya ses ayıklama işlemlerinde dosya adını (örn: b.mkv) serbestçe belirleyin.",
                    badge: "YENİ"
                ),
                .init(
                    icon: "play.tv",
                    title: "Apple QuickTime Tam Uyumluluğu",
                    description: "H.265 (HEVC) videolar artık -tag:v hvc1, yuv420p ve faststart ile QuickTime Player ve Finder QuickLook'ta anında sorunsuz açılır.",
                    badge: "DÜZELTME"
                ),
                .init(
                    icon: "arrow.triangle.2.circlepath.circle",
                    title: "Uygulama İçi Güncelleyici (Updater)",
                    description: "Üst bir sürüm yayınlandığında tek tıkla doğrudan güncelleyin ve yenilikleri anında keşfedin.",
                    badge: "GÜNCELLEME"
                ),
                .init(
                    icon: "speaker.wave.2",
                    title: "Konteyner Duyarlı Ses Kodekleri",
                    description: "MP4 ve MOV için Apple uyumlu ses formatları otomatik filtrelenir; hatalı dışa aktarma engellenir.",
                    badge: "İYİLEŞTİRME"
                )
            ]
        )
    }
    
    // MARK: - Check For Updates
    public func checkForUpdates(showFeedbackIfUpToDate: Bool = false) {
        status = .checking
        showUpdateModal = true
        
        Task {
            do {
                let tagsURL = URL(string: "https://api.github.com/repos/\(Self.repoOwner)/\(Self.repoName)/tags")!
                var request = URLRequest(url: tagsURL)
                request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 8
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    status = .error("GitHub API sunucusuna erişilemedi.")
                    return
                }
                
                struct GitHubTag: Decodable {
                    let name: String
                }
                
                let tags = try JSONDecoder().decode([GitHubTag].self, from: data)
                let highestTag = tags
                    .map { $0.name }
                    .filter { !($0.contains("alpha") || $0.contains("beta")) }
                    .sorted { isVersion($0, greaterThan: $1) }
                    .first
                
                if let latest = highestTag, isVersion(latest, greaterThan: Self.currentVersion) {
                    let releasePageURL = URL(string: "https://github.com/\(Self.repoOwner)/\(Self.repoName)/releases/tag/\(latest)")
                    status = .updateAvailable(
                        version: latest,
                        notes: "Patoo \(latest) sürümü yayınlandı! Performans artışları ve yeni özellikler içeriyor.",
                        url: releasePageURL
                    )
                } else {
                    status = .upToDate
                    if !showFeedbackIfUpToDate {
                        // Dismiss modal automatically after 1.8 seconds if up to date
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        if self.status == .upToDate {
                            self.showUpdateModal = false
                        }
                    }
                }
            } catch {
                status = .error("Güncelleme denetlenirken hata oluştu: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Apply Update Directly
    public func applyUpdate(targetVersion: String, releaseURL: URL?) {
        status = .updating(progress: 0.2, message: "Güncelleme hazırlanıyor...")
        
        Task {
            // Check if we are running in local git workspace
            let gitDir = "/Users/ufukcelen/Desktop/Dev/Patoo/Patoo"
            let isGitRepo = FileManager.default.fileExists(atPath: "\(gitDir)/.git")
            
            if isGitRepo {
                status = .updating(progress: 0.5, message: "Depodan son sürüm çekiliyor (git pull)...")
                let process = Process.makeSanitized()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
                process.arguments = ["pull", "origin", "main"]
                process.currentDirectoryURL = URL(fileURLWithPath: gitDir)
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    if process.terminationStatus == 0 {
                        status = .updated(message: "Patoo başarıyla güncellendi! Yeniliklerin devreye girmesi için uygulamayı yeniden başlatın.")
                        // Automatically pop What's New modal for the new version
                        self.showWhatsNewModal = true
                    } else {
                        // Open release URL as fallback
                        if let url = releaseURL ?? Self.repoURL as URL? {
                            NSWorkspace.shared.open(url)
                        }
                        status = .updated(message: "Sürüm sayfası tarayıcıda açıldı.")
                    }
                } catch {
                    if let url = releaseURL ?? Self.repoURL as URL? {
                        NSWorkspace.shared.open(url)
                    }
                    status = .error("Doğrudan güncelleme başarısız oldu: \(error.localizedDescription)")
                }
            } else {
                // If installed app bundle, open GitHub releases or download asset
                if let url = releaseURL ?? Self.repoURL as URL? {
                    NSWorkspace.shared.open(url)
                }
                status = .updated(message: "İndirme sayfası açıldı.")
            }
        }
    }
    
    // MARK: - Version Comparison
    public func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let clean1 = v1.trimmingCharacters(in: CharacterSet(charactersIn: "vV")).split(separator: ".").compactMap { Int($0) }
        let clean2 = v2.trimmingCharacters(in: CharacterSet(charactersIn: "vV")).split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(clean1.count, clean2.count)
        for i in 0..<maxCount {
            let p1 = i < clean1.count ? clean1[i] : 0
            let p2 = i < clean2.count ? clean2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }
}

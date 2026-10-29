//
//  AppUpdateManager.swift
//  Patoo
//

import Foundation
import SwiftUI
import Observation
import AppKit

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
    
    public static let currentVersion: String = "0.0.4"
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
            version: "v0.0.4",
            releaseDate: "Ekim 2026",
            title: "Yeni Menü Mimarisi & Gelişmiş Medya Araçları",
            features: [
                .init(
                    icon: "square.grid.2x2",
                    title: "Kişiselleştirilebilir Hızlı Eylemler",
                    description: "Genel Bakış hızlı eylemleri artık temiz başlar; istediğiniz menüden 📌 butonuyla sabitleyip kaldırabilirsiniz.",
                    badge: "ÖNE ÇIKAN"
                ),
                .init(
                    icon: "waveform",
                    title: "Ses Stüdyosu",
                    description: "Ses çıkarma, sesi tamamen kaldırma, EBU R128 normalizasyon, dB ses seviyesi ayarı ve fade geçiş efektleri.",
                    badge: "YENİ MENÜ"
                ),
                .init(
                    icon: "square.stack.3d.up",
                    title: "Toplu İşlemler",
                    description: "Klasör seçimi, toplu medya tarama, dosya başına veya genel ayarlar, kuyruk duraklatma ve toplu iptal.",
                    badge: "YENİ MENÜ"
                ),
                .init(
                    icon: "doc.text.magnifyingglass",
                    title: "Ayrıntılı Medya Bilgisi",
                    description: "Görüntü ve ses akışları, çözünürlük, kodek dökümü ve ham FFprobe JSON panoya kopyalama desteği.",
                    badge: "YENİ MENÜ"
                ),
                .init(
                    icon: "gauge.with.needle",
                    title: "Akıllı Boyut ve Kalite Tahmini",
                    description: "Sıkıştırma ekranında seçilen profile göre anlık çıktı boyutu ve tasarruf yüzdesi hesaplaması.",
                    badge: "GÜNCELLEME"
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
                request.setValue("Patoo-App-Updater", forHTTPHeaderField: "User-Agent")
                request.timeoutInterval = 10
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self.status = .error("GitHub API yanıtı: \(code)")
                    return
                }
                
                guard let tags = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                      let latestTag = tags.first,
                      let tagName = latestTag["name"] as? String else {
                    self.status = .upToDate
                    return
                }
                
                let cleanLatest = tagName.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespaces)
                let cleanCurrent = Self.currentVersion.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespaces)
                
                if isVersion(cleanLatest, greaterThan: cleanCurrent) {
                    let releaseURL = URL(string: "https://github.com/\(Self.repoOwner)/\(Self.repoName)/releases/tag/\(tagName)")
                    self.status = .updateAvailable(
                        version: tagName,
                        notes: "Patoo \(tagName) yayınlandı! Yenilikleri almak için hemen güncelleyin.",
                        url: releaseURL
                    )
                } else {
                    self.status = .upToDate
                }
            } catch {
                self.status = .error("Güncelleme denetlenemedi: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Direct In-App Update
    public func applyUpdate(targetVersion: String, releaseURL: URL?) {
        if FileManager.default.fileExists(atPath: "/Users/ufukcelen/Desktop/Dev/Patoo/Patoo/.git") {
            performDirectUpdate()
        } else if let url = releaseURL {
            NSWorkspace.shared.open(url)
            self.status = .idle
            self.showUpdateModal = false
        } else {
            performDirectUpdate()
        }
    }
    
    public func performDirectUpdate() {
        status = .updating(progress: 0.2, message: "Güncelleme indiriliyor (git pull)...")
        
        Task.detached {
            let process = Process.makeSanitized()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["pull", "origin", "main"]
            
            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stdoutPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                await MainActor.run {
                    if process.terminationStatus == 0 {
                        self.status = .updated(message: "Patoo başarıyla güncellendi! Lütfen uygulamayı yeniden başlatın.")
                        self.checkFirstLaunchForVersion()
                    } else {
                        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        let msg = String(data: outData, encoding: .utf8) ?? "Bilinmeyen hata"
                        self.status = .error("Güncelleme tamamlanamadı: \(msg)")
                    }
                }
            } catch {
                await MainActor.run {
                    self.status = .error("İşlem hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        
        let count = max(parts1.count, parts2.count)
        for i in 0..<count {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }
}

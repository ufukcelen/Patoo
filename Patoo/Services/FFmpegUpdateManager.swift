//
//  FFmpegUpdateManager.swift
//  Patoo
//

import Foundation
import SwiftUI
import Observation

public enum FFmpegUpdateStatus: Equatable, Sendable {
    case checking
    case notInstalled
    case upToDate(version: String)
    case updateAvailable(current: String, latest: String)
    case downloading(progress: Double, message: String)
    case error(String)
    
    public var isUpdating: Bool {
        if case .downloading = self { return true }
        return false
    }
}

@Observable
@MainActor
public final class FFmpegUpdateManager: NSObject, URLSessionDownloadDelegate {
    public static let shared = FFmpegUpdateManager()
    
    public var status: FFmpegUpdateStatus = .checking
    public var showUpdateModal: Bool = false
    public var latestAvailableVersion: String? = nil
    
    private var downloadTask: URLSessionDownloadTask? = nil
    private var downloadContinuation: CheckedContinuation<URL, Error>? = nil
    private var currentDownloadStepMessage: String = ""
    
    public override init() {
        super.init()
    }
    
    // MARK: - App Launch & Background Update Check
    public func checkUpdateOnLaunch(appState: AppState) {
        Task {
            await checkForUpdates(appState: appState, silent: true)
        }
    }
    
    public func checkForUpdates(appState: AppState, silent: Bool = false) async {
        let install = FFmpegLocator.shared.locate()
        
        guard install.isReady, let currentVer = install.cleanVersion else {
            self.status = .notInstalled
            return
        }
        
        self.status = .checking
        
        do {
            let latestVer = try await fetchLatestEvermeetVersion()
            self.latestAvailableVersion = latestVer
            
            if isVersion(latestVer, greaterThan: currentVer) {
                self.status = .updateAvailable(current: currentVer, latest: latestVer)
                if !silent {
                    appState.showToast("FFmpeg güncellemesi mevcut: v\(latestVer)")
                }
            } else {
                self.status = .upToDate(version: currentVer)
                if !silent {
                    appState.showToast("FFmpeg güncel (v\(currentVer))")
                }
            }
        } catch {
            // If offline, stay in upToDate or keep current ready state
            self.status = .upToDate(version: currentVer)
        }
    }
    
    // MARK: - Perform Install or Update
    public func performInstallOrUpdate(appState: AppState) {
        let install = FFmpegLocator.shared.locate()
        
        // If system is using Homebrew and brew CLI is installed, try Homebrew upgrade
        if install.source == .homebrew, isBrewAvailable() {
            performHomebrewUpgrade(appState: appState)
            return
        }
        
        // Default standalone managed installation: Download official static builds
        performStandaloneDownload(appState: appState)
    }
    
    private func performHomebrewUpgrade(appState: AppState) {
        status = .downloading(progress: 0.1, message: "Homebrew ile FFmpeg güncelleniyor...")
        
        Task.detached {
            let process = Process.makeSanitized()
            let brewPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["upgrade", "ffmpeg"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                await MainActor.run {
                    appState.refreshInstallation()
                    let updatedInstall = appState.ffmpegInstallation
                    if updatedInstall.isReady, let ver = updatedInstall.cleanVersion {
                        self.status = .upToDate(version: ver)
                        appState.showToast("FFmpeg başarıyla güncellendi (v\(ver))")
                    } else {
                        self.status = .error("Homebrew güncellemesi tamamlanamadı")
                    }
                }
            } catch {
                await MainActor.run {
                    self.status = .error("İşlem hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performStandaloneDownload(appState: AppState) {
        Task {
            do {
                let binDir = FFmpegLocator.managedBinDirectory
                try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
                
                // 1. Fetch download URLs
                self.status = .downloading(progress: 0.05, message: "İndirme bilgileri alınıyor...")
                let (ffmpegZipURL, latestVer) = try await fetchDownloadURL(for: "ffmpeg")
                let (ffprobeZipURL, _) = try await fetchDownloadURL(for: "ffprobe")
                
                // 2. Download ffmpeg
                self.currentDownloadStepMessage = "FFmpeg indiriliyor..."
                self.status = .downloading(progress: 0.15, message: "FFmpeg indiriliyor (%0)...")
                let localFFmpegZip = try await downloadWithProgress(from: ffmpegZipURL, stepOffset: 0.1, stepSpan: 0.4)
                
                // 3. Download ffprobe
                self.currentDownloadStepMessage = "FFprobe indiriliyor..."
                self.status = .downloading(progress: 0.55, message: "FFprobe indiriliyor (%0)...")
                let localFFprobeZip = try await downloadWithProgress(from: ffprobeZipURL, stepOffset: 0.55, stepSpan: 0.3)
                
                // 4. Extract
                self.status = .downloading(progress: 0.90, message: "Dosyalar açılıyor ve kuruluyor...")
                try extractZip(at: localFFmpegZip, destinationDir: binDir)
                try extractZip(at: localFFprobeZip, destinationDir: binDir)
                
                // Cleanup temp zips
                try? FileManager.default.removeItem(at: localFFmpegZip)
                try? FileManager.default.removeItem(at: localFFprobeZip)
                
                // 5. Remove quarantine & chmod +x
                let ffmpegBin = binDir.appendingPathComponent("ffmpeg")
                let ffprobeBin = binDir.appendingPathComponent("ffprobe")
                makeExecutable(fileURL: ffmpegBin)
                makeExecutable(fileURL: ffprobeBin)
                
                // 6. Refresh App State
                appState.refreshInstallation()
                
                self.status = .upToDate(version: latestVer)
                appState.showToast("FFmpeg ve FFprobe başarıyla kuruldu (v\(latestVer))!")
            } catch {
                self.status = .error(error.localizedDescription)
                appState.showToast("FFmpeg kurulumu başarısız: \(error.localizedDescription)", isError: true)
            }
        }
    }
    
    // MARK: - API Helpers
    private func fetchLatestEvermeetVersion() async throws -> String {
        let (url, _) = try await fetchDownloadURL(for: "ffmpeg")
        // Version is parsed in fetchDownloadURL
        return latestAvailableVersion ?? "Son Sürüm"
    }
    
    private func fetchDownloadURL(for tool: String) async throws -> (URL, String) {
        let apiURL = URL(string: "https://evermeet.cx/ffmpeg/info/\(tool)/release")!
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 8
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "FFmpegUpdate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sunucu yanıt vermedi"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = json["version"] as? String,
              let download = json["download"] as? [String: Any],
              let zipInfo = download["zip"] as? [String: Any],
              let urlStr = zipInfo["url"] as? String,
              let downloadURL = URL(string: urlStr) else {
            throw NSError(domain: "FFmpegUpdate", code: 2, userInfo: [NSLocalizedDescriptionKey: "Geçersiz FFmpeg indirme bilgisi"])
        }
        
        self.latestAvailableVersion = version
        return (downloadURL, version)
    }
    
    // MARK: - Download With Progress
    private func downloadWithProgress(from url: URL, stepOffset: Double, stepSpan: Double) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.downloadContinuation = continuation
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
            let task = session.downloadTask(with: url)
            self.downloadTask = task
            task.resume()
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let percent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let percentInt = Int(percent * 100)
        self.status = .downloading(progress: percent, message: "\(currentDownloadStepMessage) (%\(percentInt))")
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueName = UUID().uuidString + ".zip"
        let dest = tempDir.appendingPathComponent(uniqueName)
        
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            downloadContinuation?.resume(returning: dest)
            downloadContinuation = nil
        } catch {
            downloadContinuation?.resume(throwing: error)
            downloadContinuation = nil
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            downloadContinuation?.resume(throwing: error)
            downloadContinuation = nil
        }
    }
    
    // MARK: - File Utilities
    private func extractZip(at zipURL: URL, destinationDir: URL) throws {
        let process = Process.makeSanitized()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", zipURL.path, "-d", destinationDir.path]
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "FFmpegUpdate", code: 3, userInfo: [NSLocalizedDescriptionKey: "Arşiv açılamadı"])
        }
    }
    
    private func makeExecutable(fileURL: URL) {
        // Remove quarantine attribute
        let xattr = Process.makeSanitized()
        xattr.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        xattr.arguments = ["-d", "com.apple.quarantine", fileURL.path]
        try? xattr.run()
        xattr.waitUntilExit()
        
        // chmod +x
        let chmod = Process.makeSanitized()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["+x", fileURL.path]
        try? chmod.run()
        chmod.waitUntilExit()
    }
    
    private func isBrewAvailable() -> Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") ||
        FileManager.default.fileExists(atPath: "/usr/local/bin/brew")
    }
    
    private func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let p1 = v1.split(separator: ".").compactMap { Int($0) }
        let p2 = v2.split(separator: ".").compactMap { Int($0) }
        
        let count = max(p1.count, p2.count)
        for i in 0..<count {
            let val1 = i < p1.count ? p1[i] : 0
            let val2 = i < p2.count ? p2[i] : 0
            if val1 > val2 { return true }
            if val1 < val2 { return false }
        }
        return false
    }
}

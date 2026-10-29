//
//  FFmpegLocator.swift
//  Patoo
//

import Foundation

public enum FFmpegSource: String, Sendable, Equatable {
    case managed = "Patoo Alanı (Otomatik)"
    case homebrew = "Homebrew"
    case custom = "Özel Yol"
    case system = "Sistem"
    case none = "Bulunamadı"
}

public struct FFmpegInstallation: Sendable, Equatable {
    public let ffmpegURL: URL?
    public let ffprobeURL: URL?
    public let version: String?
    public let cleanVersion: String?
    public let source: FFmpegSource
    public let isReady: Bool
    
    public static let missing = FFmpegInstallation(
        ffmpegURL: nil,
        ffprobeURL: nil,
        version: nil,
        cleanVersion: nil,
        source: .none,
        isReady: false
    )
}

public final class FFmpegLocator: Sendable {
    public static let shared = FFmpegLocator()
    
    private let customFFmpegKey = "custom_ffmpeg_path"
    private let customFFprobeKey = "custom_ffprobe_path"
    
    public init() {}
    
    public static var managedBinDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Patoo/bin", isDirectory: true)
    }
    
    public func locate() -> FFmpegInstallation {
        let fileManager = FileManager.default
        let customFFmpeg = UserDefaults.standard.string(forKey: customFFmpegKey)
        let customFFprobe = UserDefaults.standard.string(forKey: customFFprobeKey)
        
        let ffmpegURL = findExecutable(name: "ffmpeg", customKey: customFFmpegKey)
        let ffprobeURL = findExecutable(name: "ffprobe", customKey: customFFprobeKey)
        
        guard let ffmpeg = ffmpegURL, let ffprobe = ffprobeURL else {
            return FFmpegInstallation(
                ffmpegURL: ffmpegURL,
                ffprobeURL: ffprobeURL,
                version: nil,
                cleanVersion: nil,
                source: .none,
                isReady: false
            )
        }
        
        let rawVersion = detectVersion(ffmpegURL: ffmpeg)
        let clean = extractCleanVersion(from: rawVersion ?? "")
        let source = determineSource(url: ffmpeg, customPath: customFFmpeg)
        
        return FFmpegInstallation(
            ffmpegURL: ffmpeg,
            ffprobeURL: ffprobe,
            version: rawVersion,
            cleanVersion: clean,
            source: source,
            isReady: true
        )
    }
    
    public func saveCustomPaths(ffmpegPath: String?, ffprobePath: String?) {
        let defaults = UserDefaults.standard
        if let ffmpegPath = ffmpegPath, !ffmpegPath.isEmpty {
            defaults.set(ffmpegPath, forKey: customFFmpegKey)
        } else {
            defaults.removeObject(forKey: customFFmpegKey)
        }
        
        if let ffprobePath = ffprobePath, !ffprobePath.isEmpty {
            defaults.set(ffprobePath, forKey: customFFprobeKey)
        } else {
            defaults.removeObject(forKey: customFFprobeKey)
        }
    }
    
    private func determineSource(url: URL, customPath: String?) -> FFmpegSource {
        let path = url.path
        if let custom = customPath, path == custom {
            return .custom
        }
        if path.hasPrefix(Self.managedBinDirectory.path) {
            return .managed
        }
        if path.contains("/homebrew/") || path.hasPrefix("/opt/homebrew/") || path.hasPrefix("/usr/local/Cellar/") {
            return .homebrew
        }
        return .system
    }
    
    private func findExecutable(name: String, customKey: String) -> URL? {
        let fileManager = FileManager.default
        
        // 1. Check custom user-defined path
        if let customPath = UserDefaults.standard.string(forKey: customKey),
           fileManager.isExecutableFile(atPath: customPath) {
            return URL(fileURLWithPath: customPath)
        }
        
        // 2. Check Patoo managed directory (~/Library/Application Support/Patoo/bin)
        let managedPath = Self.managedBinDirectory.appendingPathComponent(name).path
        if fileManager.isExecutableFile(atPath: managedPath) {
            return URL(fileURLWithPath: managedPath)
        }
        
        // 3. Check well-known macOS locations
        let candidatePaths = [
            "/opt/homebrew/bin/\(name)",        // Apple Silicon Homebrew
            "/usr/local/bin/\(name)",           // Intel Homebrew / local builds
            "/opt/local/bin/\(name)",           // MacPorts
            "/usr/bin/\(name)",                 // System /usr/bin
            "/bin/\(name)"
        ]
        
        for path in candidatePaths {
            if fileManager.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        
        // 4. Fallback: ask login shell PATH via zsh
        if let shellFoundPath = queryShellWhich(name: name),
           fileManager.isExecutableFile(atPath: shellFoundPath) {
            return URL(fileURLWithPath: shellFoundPath)
        }
        
        return nil
    }
    
    private func queryShellWhich(name: String) -> String? {
        let process = Process.makeSanitized()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "which \(name)"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !str.isEmpty {
                    return str
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func detectVersion(ffmpegURL: URL) -> String? {
        let process = Process.makeSanitized()
        process.executableURL = ffmpegURL
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            if let output = String(data: data, encoding: .utf8) {
                if let firstLine = output.components(separatedBy: .newlines).first, !firstLine.isEmpty {
                    return firstLine
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func extractCleanVersion(from raw: String) -> String? {
        let pattern = #"version\s+([0-9]+(?:\.[0-9]+)*)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
           let range = Range(match.range(at: 1), in: raw) {
            return String(raw[range])
        }
        return nil
    }
}

extension Process {
    public static func makeSanitized() -> Process {
        let process = Process()
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "DYLD_INSERT_LIBRARIES")
        env.removeValue(forKey: "DYLD_LIBRARY_PATH")
        env.removeValue(forKey: "DYLD_FRAMEWORK_PATH")
        env.removeValue(forKey: "OS_ACTIVITY_DT_MODE")
        process.environment = env
        return process
    }
}

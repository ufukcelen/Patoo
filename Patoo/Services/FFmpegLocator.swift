//
//  FFmpegLocator.swift
//  Patoo
//

import Foundation

public struct FFmpegInstallation: Sendable, Equatable {
    public let ffmpegURL: URL?
    public let ffprobeURL: URL?
    public let version: String?
    public let isReady: Bool
    
    public static let missing = FFmpegInstallation(
        ffmpegURL: nil,
        ffprobeURL: nil,
        version: nil,
        isReady: false
    )
}

public final class FFmpegLocator: Sendable {
    public static let shared = FFmpegLocator()
    
    private let customFFmpegKey = "custom_ffmpeg_path"
    private let customFFprobeKey = "custom_ffprobe_path"
    
    public init() {}
    
    public func locate() -> FFmpegInstallation {
        let ffmpegURL = findExecutable(name: "ffmpeg", customKey: customFFmpegKey)
        let ffprobeURL = findExecutable(name: "ffprobe", customKey: customFFprobeKey)
        
        guard let ffmpeg = ffmpegURL, let ffprobe = ffprobeURL else {
            return FFmpegInstallation(
                ffmpegURL: ffmpegURL,
                ffprobeURL: ffprobeURL,
                version: nil,
                isReady: false
            )
        }
        
        let version = detectVersion(ffmpegURL: ffmpeg)
        return FFmpegInstallation(
            ffmpegURL: ffmpeg,
            ffprobeURL: ffprobe,
            version: version,
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
    
    private func findExecutable(name: String, customKey: String) -> URL? {
        let fileManager = FileManager.default
        
        // 1. Check custom user-defined path
        if let customPath = UserDefaults.standard.string(forKey: customKey),
           fileManager.isExecutableFile(atPath: customPath) {
            return URL(fileURLWithPath: customPath)
        }
        
        // 2. Check well-known macOS locations
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
        
        // 3. Fallback: ask login shell PATH via zsh
        if let shellFoundPath = queryShellWhich(name: name),
           fileManager.isExecutableFile(atPath: shellFoundPath) {
            return URL(fileURLWithPath: shellFoundPath)
        }
        
        return nil
    }
    
    private func queryShellWhich(name: String) -> String? {
        let process = Process()
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
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // First line is e.g. "ffmpeg version 7.1 Copyright (c) 2000-2024 the FFmpeg developers"
                if let firstLine = output.components(separatedBy: .newlines).first {
                    return firstLine
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
}

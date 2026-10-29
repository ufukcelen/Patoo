//
//  FFprobeService.swift
//  Patoo
//

import Foundation

public enum FFprobeError: LocalizedError, Sendable {
    case ffprobeNotFound
    case processExecutionFailed(String)
    case parsingFailed(String)
    case invalidMediaFile(String)
    
    public var errorDescription: String? {
        switch self {
        case .ffprobeNotFound:
            return "FFprobe sistemde bulunamadı. Lütfen Ayarlar sayfasından FFprobe konumunu kontrol edin veya Homebrew ile yükleyin ('brew install ffmpeg')."
        case .processExecutionFailed(let msg):
            return "FFprobe çalıştırılırken hata oluştu: \(msg)"
        case .parsingFailed(let msg):
            return "Medya bilgileri okunamadı veya dosya formatı desteklenmiyor: \(msg)"
        case .invalidMediaFile(let msg):
            return "Geçersiz medya dosyası: \(msg)"
        }
    }
}

public final class FFprobeService: Sendable {
    public static let shared = FFprobeService()
    
    public init() {}
    
    public func analyze(fileURL: URL) async throws -> MediaMetadata {
        guard let ffprobeURL = FFmpegLocator.shared.locate().ffprobeURL else {
            throw FFprobeError.ffprobeNotFound
        }
        
        let path = fileURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            throw FFprobeError.invalidMediaFile("Dosya mevcut değil: \(fileURL.lastPathComponent)")
        }
        
        let fileSize: Int64
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        } else {
            fileSize = 0
        }
        
        // Execute ffprobe asynchronously on a detached task
        return try await Task.detached {
            let process = Process.makeSanitized()
            process.executableURL = ffprobeURL
            process.arguments = [
                "-v", "quiet",
                "-print_format", "json",
                "-show_format",
                "-show_streams",
                path
            ]
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            do {
                try process.run()
            } catch {
                throw FFprobeError.processExecutionFailed(error.localizedDescription)
            }
            
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let errStr = String(data: stderrData, encoding: .utf8) ?? "Bilinmeyen hata"
                throw FFprobeError.processExecutionFailed("Çıkış kodu: \(process.terminationStatus). \(errStr)")
            }
            
            do {
                let decoded = try JSONDecoder().decode(FFprobeOutput.self, from: stdoutData)
                let metadata = MediaMetadata.from(ffprobe: decoded, fileURL: fileURL, fallbackFileSize: fileSize)
                return metadata
            } catch {
                throw FFprobeError.parsingFailed(error.localizedDescription)
            }
        }.value
    }
}

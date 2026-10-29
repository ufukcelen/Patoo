//
//  FFmpegProcessRunner.swift
//  Patoo
//

import Foundation

public enum FFmpegExecutionError: LocalizedError, Sendable {
    case binaryNotFound
    case processFailed(exitCode: Int32, logSnippet: String)
    case cancelled
    case outputFileNotFound(URL)
    case outputFileEmpty(URL)
    case launchError(String)
    
    public var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "FFmpeg çalıştırılabilir dosyası bulunamadı."
        case .processFailed(let code, let snippet):
            return "FFmpeg işlemi hata ile sonuçlandı (Kod: \(code)). Detay: \(snippet)"
        case .cancelled:
            return "İşlem kullanıcı tarafından iptal edildi."
        case .outputFileNotFound(let url):
            return "İşlem tamamlandı ancak çıktı dosyası bulunamadı: \(url.lastPathComponent)"
        case .outputFileEmpty(let url):
            return "Çıktı dosyası oluşturuldu fakat dosya boyutu 0 bayt: \(url.lastPathComponent)"
        case .launchError(let msg):
            return "Süreç başlatılamadı: \(msg)"
        }
    }
}

public actor FFmpegProcessRunner {
    private var currentProcess: Process?
    private var isCancelled = false
    
    public init() {}
    
    public func cancel() {
        isCancelled = true
        if let process = currentProcess, process.isRunning {
            process.terminate()
        }
    }
    
    public func run(
        command: FFmpegCommand,
        totalDurationSeconds: Double,
        onProgress: @Sendable @escaping (ProgressSnapshot) -> Void,
        onLogChunk: @Sendable @escaping (String) -> Void
    ) async throws {
        guard let ffmpegURL = FFmpegLocator.shared.locate().ffmpegURL else {
            throw FFmpegExecutionError.binaryNotFound
        }
        
        isCancelled = false
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = command.arguments
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        let progressParser = FFmpegProgressParser(totalDurationSeconds: totalDurationSeconds)
        
        // Progress pipe reader (stdout)
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            let snapshots = progressParser.parseLineChunk(text)
            for snapshot in snapshots {
                onProgress(snapshot)
            }
        }
        
        // Stderr reader (logs and errors)
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            onLogChunk(text)
        }
        
        currentProcess = process
        
        do {
            try process.run()
        } catch {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            throw FFmpegExecutionError.launchError(error.localizedDescription)
        }
        
        // Await process termination without blocking threads
        let exitCode: Int32 = await withCheckedContinuation { continuation in
            process.terminationHandler = { proc in
                continuation.resume(returning: proc.terminationStatus)
            }
        }
        
        // Clean up handlers
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
        
        if isCancelled {
            // Delete incomplete output if present
            try? FileManager.default.removeItem(at: command.outputURL)
            throw FFmpegExecutionError.cancelled
        }
        
        if exitCode != 0 {
            throw FFmpegExecutionError.processFailed(
                exitCode: exitCode,
                logSnippet: "FFmpeg işlemi çıkış kodu: \(exitCode)"
            )
        }
        
        // Verify output file existence & non-zero size
        guard FileManager.default.fileExists(atPath: command.outputURL.path) else {
            throw FFmpegExecutionError.outputFileNotFound(command.outputURL)
        }
        
        let attrs = try? FileManager.default.attributesOfItem(atPath: command.outputURL.path)
        let fileSize = (attrs?[.size] as? Int64) ?? 0
        guard fileSize > 0 else {
            try? FileManager.default.removeItem(at: command.outputURL)
            throw FFmpegExecutionError.outputFileEmpty(command.outputURL)
        }
        
        // Final 100% progress report
        onProgress(ProgressSnapshot(
            progress: 1.0,
            currentTimeSeconds: totalDurationSeconds,
            speed: "1.0x",
            fps: "0",
            estimatedRemainingSeconds: 0,
            isComplete: true
        ))
    }
}

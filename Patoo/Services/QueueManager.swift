//
//  QueueManager.swift
//  Patoo
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class QueueManager {
    public static let shared = QueueManager()
    
    public var jobs: [MediaJob] = []
    public var activeJobId: UUID? = nil
    public var isProcessing: Bool = false
    
    private var runnerTask: Task<Void, Never>?
    private var activeRunner: FFmpegProcessRunner?
    
    public init() {}
    
    public var activeJob: MediaJob? {
        guard let id = activeJobId else { return nil }
        return jobs.first(where: { $0.id == id })
    }
    
    public var pendingCount: Int {
        jobs.filter { $0.status == .pending }.count
    }
    
    public var completedCount: Int {
        jobs.filter {
            if case .completed = $0.status { return true }
            return false
        }.count
    }
    
    public var failedCount: Int {
        jobs.filter {
            if case .failed = $0.status { return true }
            return false
        }.count
    }
    
    // MARK: - Queue Actions
    public func enqueue(
        sourceURL: URL,
        sourceMetadata: MediaMetadata?,
        targetURL: URL,
        type: JobType
    ) {
        let job = MediaJob(
            sourceURL: sourceURL,
            sourceMetadata: sourceMetadata,
            targetURL: targetURL,
            type: type,
            status: .pending
        )
        jobs.append(job)
        processNextIfPossible()
    }
    
    public func cancelJob(id: UUID) {
        if activeJobId == id {
            Task {
                await activeRunner?.cancel()
            }
        }
        
        if let index = jobs.firstIndex(where: { $0.id == id }) {
            jobs[index].status = .cancelled
        }
        
        if activeJobId == id {
            activeJobId = nil
            activeRunner = nil
            processNextIfPossible()
        }
    }
    
    public func retryJob(id: UUID) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].status = .pending
        jobs[index].rawLog = ""
        processNextIfPossible()
    }
    
    public func removeJob(id: UUID) {
        if activeJobId == id {
            cancelJob(id: id)
        }
        jobs.removeAll(where: { $0.id == id })
    }
    
    public func clearCompleted() {
        jobs.removeAll { job in
            if case .completed = job.status { return true }
            if case .cancelled = job.status { return true }
            return false
        }
    }
    
    // MARK: - Process Execution Loop
    public func processNextIfPossible() {
        guard !isProcessing else { return }
        guard let nextIndex = jobs.firstIndex(where: { $0.status == .pending }) else {
            activeJobId = nil
            isProcessing = false
            return
        }
        
        isProcessing = true
        let job = jobs[nextIndex]
        activeJobId = job.id
        jobs[nextIndex].status = .processing(progress: 0.0, speed: "0x", fps: "0", timeRemaining: nil)
        
        runnerTask = Task { [weak self] in
            await self?.executeJob(id: job.id)
        }
    }
    
    private func executeJob(id: UUID) async {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else {
            isProcessing = false
            return
        }
        
        let job = jobs[index]
        
        // 1. Build Command
        let command: FFmpegCommand
        switch job.type {
        case .convert(let config):
            command = FFmpegCommandBuilder.buildConvertCommand(
                inputURL: job.sourceURL,
                outputURL: job.targetURL,
                config: config
            )
        case .compress(let config):
            command = FFmpegCommandBuilder.buildCompressCommand(
                inputURL: job.sourceURL,
                outputURL: job.targetURL,
                config: config
            )
        case .extractAudio(let config):
            command = FFmpegCommandBuilder.buildAudioExtractCommand(
                inputURL: job.sourceURL,
                outputURL: job.targetURL,
                config: config,
                sourceAudioCodec: job.sourceMetadata?.primaryAudio?.codec
            )
        }
        
        // 2. Total duration from metadata or 1.0
        let totalDuration = job.sourceMetadata?.durationSeconds ?? 0.0
        
        // 3. Runner
        let runner = FFmpegProcessRunner()
        self.activeRunner = runner
        
        do {
            try await runner.run(
                command: command,
                totalDurationSeconds: totalDuration,
                onProgress: { [weak self] snapshot in
                    Task { @MainActor in
                        guard let self = self,
                              let idx = self.jobs.firstIndex(where: { $0.id == id }) else { return }
                        self.jobs[idx].status = .processing(
                            progress: snapshot.progress,
                            speed: snapshot.speed,
                            fps: snapshot.fps,
                            timeRemaining: snapshot.formattedRemainingTime
                        )
                    }
                },
                onLogChunk: { [weak self] chunk in
                    Task { @MainActor in
                        guard let self = self,
                              let idx = self.jobs.firstIndex(where: { $0.id == id }) else { return }
                        self.jobs[idx].rawLog.append(chunk)
                        // Keep last 15KB of log to prevent memory blowup
                        if self.jobs[idx].rawLog.count > 15000 {
                            self.jobs[idx].rawLog = String(self.jobs[idx].rawLog.suffix(10000))
                        }
                    }
                }
            )
            
            // Mark completed
            if let idx = jobs.firstIndex(where: { $0.id == id }) {
                jobs[idx].status = .completed(outputURL: job.targetURL, finishedAt: Date())
            }
        } catch {
            if let idx = jobs.firstIndex(where: { $0.id == id }) {
                if let execErr = error as? FFmpegExecutionError, case .cancelled = execErr {
                    jobs[idx].status = .cancelled
                } else {
                    let snippet = jobs[idx].rawLog.suffix(300)
                    jobs[idx].status = .failed(
                        error: error.localizedDescription,
                        logSnippet: String(snippet)
                    )
                }
            }
        }
        
        self.activeRunner = nil
        self.activeJobId = nil
        self.isProcessing = false
        
        // Advance to next pending item
        processNextIfPossible()
    }
}

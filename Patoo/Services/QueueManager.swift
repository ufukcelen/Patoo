//
//  QueueManager.swift
//  Patoo
//

import Foundation
import Observation

@Observable
@MainActor
public final class QueueManager {
    public static let shared = QueueManager()
    
    public var jobs: [MediaJob] = []
    public var activeJobId: UUID? = nil
    public var isProcessing: Bool = false
    public var isPaused: Bool = false
    
    private var activeRunner: FFmpegProcessRunner? = nil
    private var runnerTask: Task<Void, Never>? = nil
    
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
    
    public func pauseQueue() {
        isPaused = true
    }
    
    public func resumeQueue() {
        isPaused = false
        processNextIfPossible()
    }
    
    public func cancelAll() {
        for job in jobs where !job.status.isTerminal {
            cancelJob(id: job.id)
        }
    }
    
    public func cancelJob(id: UUID) {
        if activeJobId == id {
            let runner = activeRunner
            Task {
                await runner?.cancel()
            }
            if let index = jobs.firstIndex(where: { $0.id == id }) {
                jobs[index].status = .cancelled
            }
        } else if let index = jobs.firstIndex(where: { $0.id == id }) {
            jobs[index].status = .cancelled
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
        guard !isProcessing && !isPaused else { return }
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
        case .audioStudio(let config):
            command = FFmpegCommandBuilder.buildAudioStudioCommand(
                inputURL: job.sourceURL,
                outputURL: job.targetURL,
                config: config,
                sourceMetadata: job.sourceMetadata
            )
        case .batch:
            // Standard conversion fallback for generic batch job
            command = FFmpegCommandBuilder.buildConvertCommand(
                inputURL: job.sourceURL,
                outputURL: job.targetURL,
                config: ConversionConfig()
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
                    }
                }
            )
            
            // Success
            if let idx = self.jobs.firstIndex(where: { $0.id == id }) {
                self.jobs[idx].status = .completed(outputURL: job.targetURL, finishedAt: Date())
                self.jobs[idx].progress = 1.0
            }
        } catch {
            if let idx = self.jobs.firstIndex(where: { $0.id == id }) {
                if case .cancelled = self.jobs[idx].status {
                    // Retain cancelled state
                } else {
                    let snippet = self.jobs[idx].rawLog.components(separatedBy: "\n").suffix(15).joined(separator: "\n")
                    self.jobs[idx].status = .failed(error: error.localizedDescription, logSnippet: snippet)
                }
            }
        }
        
        self.activeRunner = nil
        self.activeJobId = nil
        self.isProcessing = false
        
        // Chain next job
        processNextIfPossible()
    }
}

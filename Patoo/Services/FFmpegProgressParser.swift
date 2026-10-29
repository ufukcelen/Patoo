//
//  FFmpegProgressParser.swift
//  Patoo
//

import Foundation

public struct ProgressSnapshot: Sendable, Equatable {
    public let progress: Double // 0.0 to 1.0
    public let currentTimeSeconds: Double
    public let speed: String
    public let fps: String
    public let estimatedRemainingSeconds: Double?
    public let isComplete: Bool
    
    public var formattedRemainingTime: String? {
        guard let remaining = estimatedRemainingSeconds, remaining.isFinite, remaining > 0 else {
            return nil
        }
        let total = Int(remaining.rounded())
        let m = total / 60
        let s = total % 60
        if m > 0 {
            return String(format: "%d dk %02d sn kaldı", m, s)
        } else {
            return String(format: "%d sn kaldı", s)
        }
    }
}

public final class FFmpegProgressParser: Sendable {
    private let totalDurationSeconds: Double
    
    public init(totalDurationSeconds: Double) {
        self.totalDurationSeconds = max(totalDurationSeconds, 0.001)
    }
    
    public func parseLineChunk(_ chunk: String) -> [ProgressSnapshot] {
        var results: [ProgressSnapshot] = []
        var currentDict: [String: String] = [:]
        
        let lines = chunk.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            let key = parts[0]
            let value = parts[1]
            currentDict[key] = value
            
            if key == "progress" {
                let snapshot = buildSnapshot(from: currentDict, isComplete: (value == "end"))
                results.append(snapshot)
                currentDict.removeAll(keepingCapacity: true)
            }
        }
        
        return results
    }
    
    private func buildSnapshot(from dict: [String: String], isComplete: Bool) -> ProgressSnapshot {
        if isComplete {
            return ProgressSnapshot(
                progress: 1.0,
                currentTimeSeconds: totalDurationSeconds,
                speed: dict["speed"] ?? "1.0x",
                fps: dict["fps"] ?? "0",
                estimatedRemainingSeconds: 0,
                isComplete: true
            )
        }
        
        var currentTime = 0.0
        if let outTimeUs = dict["out_time_us"], let us = Double(outTimeUs) {
            currentTime = us / 1_000_000.0
        } else if let outTimeMs = dict["out_time_ms"], let ms = Double(outTimeMs) {
            currentTime = ms / 1000.0
        } else if let outTime = dict["out_time"] {
            currentTime = parseTimecode(outTime)
        }
        
        let rawProgress = min(max(currentTime / totalDurationSeconds, 0.0), 0.99)
        let speedStr = dict["speed"] ?? "1.0x"
        let fpsStr = dict["fps"] ?? "0"
        
        // Calculate remaining seconds based on speed
        let speedMultiplier: Double = {
            let cleaned = speedStr.replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .whitespaces)
            return Double(cleaned) ?? 1.0
        }()
        
        let remainingSeconds: Double? = {
            guard speedMultiplier > 0.05, currentTime > 0 else { return nil }
            let remainingWork = max(totalDurationSeconds - currentTime, 0.0)
            return remainingWork / speedMultiplier
        }()
        
        return ProgressSnapshot(
            progress: rawProgress,
            currentTimeSeconds: currentTime,
            speed: speedStr,
            fps: fpsStr,
            estimatedRemainingSeconds: remainingSeconds,
            isComplete: false
        )
    }
    
    private func parseTimecode(_ timecode: String) -> Double {
        let parts = timecode.split(separator: ":")
        guard parts.count == 3 else { return 0 }
        let hours = Double(parts[0]) ?? 0
        let minutes = Double(parts[1]) ?? 0
        let seconds = Double(parts[2]) ?? 0
        return (hours * 3600) + (minutes * 60) + seconds
    }
}

//
//  Job.swift
//  Patoo
//

import Foundation

public enum JobType: Sendable, Equatable {
    case convert(ConversionConfig)
    case compress(CompressionConfig)
    case extractAudio(AudioExtractionConfig)
    
    public var title: String {
        switch self {
        case .convert: return "Dönüştürme"
        case .compress: return "Sıkıştırma"
        case .extractAudio: return "Ses Çıkarma"
        }
    }
    
    public var iconName: String {
        switch self {
        case .convert: return "arrow.triangle.2.circlepath"
        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .extractAudio: return "waveform"
        }
    }
}

public enum JobStatus: Sendable, Equatable {
    case pending
    case processing(progress: Double, speed: String, fps: String, timeRemaining: String?)
    case completed(outputURL: URL, finishedAt: Date)
    case failed(error: String, logSnippet: String)
    case cancelled
    
    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled: return true
        case .pending, .processing: return false
        }
    }
    
    public var title: String {
        switch self {
        case .pending: return "Bekliyor"
        case .processing: return "İşleniyor"
        case .completed: return "Tamamlandı"
        case .failed: return "Başarısız"
        case .cancelled: return "İptal Edildi"
        }
    }
}

public struct MediaJob: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let createdAt: Date
    public let sourceURL: URL
    public var sourceMetadata: MediaMetadata?
    public var targetURL: URL
    public let type: JobType
    public var status: JobStatus
    public var rawLog: String
    
    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        sourceURL: URL,
        sourceMetadata: MediaMetadata? = nil,
        targetURL: URL,
        type: JobType,
        status: JobStatus = .pending,
        rawLog: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.sourceURL = sourceURL
        self.sourceMetadata = sourceMetadata
        self.targetURL = targetURL
        self.type = type
        self.status = status
        self.rawLog = rawLog
    }
    
    public var fileName: String {
        sourceURL.lastPathComponent
    }
    
    public var progress: Double {
        switch status {
        case .pending: return 0.0
        case .processing(let progress, _, _, _): return progress
        case .completed: return 1.0
        case .failed, .cancelled: return 0.0
        }
    }
}

//
//  AudioExtractionConfig.swift
//  Patoo
//

import Foundation

public enum AudioExtractFormat: String, CaseIterable, Identifiable, Sendable {
    case mp3 = "mp3"
    case aac = "m4a"
    case wav = "wav"
    case flac = "flac"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .mp3: return "MP3 (Evrensel Uyumluluk)"
        case .aac: return "AAC / M4A (Apple & Modern Web)"
        case .wav: return "WAV (Kayıpsız PCM)"
        case .flac: return "FLAC (Kayıpsız Sıkıştırma)"
        }
    }
    
    public var fileExtension: String {
        rawValue
    }
    
    public var defaultCodec: String {
        switch self {
        case .mp3: return "libmp3lame"
        case .aac: return "aac"
        case .wav: return "pcm_s16le"
        case .flac: return "flac"
        }
    }
    
    public var supportsBitrateSelection: Bool {
        self == .mp3 || self == .aac
    }
}

public enum AudioBitrate: Int, CaseIterable, Identifiable, Sendable {
    case kbps128 = 128
    case kbps192 = 192
    case kbps256 = 256
    case kbps320 = 320
    
    public var id: Int { rawValue }
    
    public var displayName: String {
        "\(rawValue) kbps"
    }
}

public struct AudioExtractionConfig: Sendable, Equatable {
    public var format: AudioExtractFormat = .mp3
    public var bitrate: AudioBitrate = .kbps256
    public var tryPassthroughIfCompatible: Bool = true
    
    public init() {}
}

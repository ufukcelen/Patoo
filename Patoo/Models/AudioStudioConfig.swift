//
//  AudioStudioConfig.swift
//  Patoo
//

import Foundation

public enum AudioStudioMode: String, CaseIterable, Identifiable, Sendable {
    case extract = "extract"
    case removeAudio = "removeAudio"
    case normalize = "normalize"
    case volume = "volume"
    case fade = "fade"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .extract: return "Ses Çıkarma"
        case .removeAudio: return "Sesi Kaldır"
        case .normalize: return "Normalizasyon"
        case .volume: return "Ses Seviyesi"
        case .fade: return "Fade Efektleri"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .extract: return "Videodaki sesi MP3, AAC, FLAC veya WAV formatında dışa aktarın."
        case .removeAudio: return "Videodaki ses akışını tamamen silip sessiz video oluşturun."
        case .normalize: return "EBU R128 standardında dengeli ve profesyonel ses seviyesi sağlayın."
        case .volume: return "Ses düzeyini desibel (dB) veya katsayı olarak artırıp azaltın."
        case .fade: return "Videonun/sesin başına Fade-In, sonuna Fade-Out yumuşak geçişi ekleyin."
        }
    }
    
    public var iconName: String {
        switch self {
        case .extract: return "arrow.up.doc"
        case .removeAudio: return "speaker.slash"
        case .normalize: return "waveform.badge.magnifyingglass"
        case .volume: return "speaker.wave.3"
        case .fade: return "chart.line.uptrend.xyaxis"
        }
    }
}

public struct AudioStudioConfig: Sendable, Equatable {
    public var mode: AudioStudioMode = .extract
    
    // 1. Extraction config
    public var extractionConfig: AudioExtractionConfig = AudioExtractionConfig()
    
    // 2. Normalization options
    public var targetLUFS: Double = -16.0 // -16 LUFS (YouTube / Podcast), -23 LUFS (EBU Broadcast)
    
    // 3. Volume adjustment options
    public var volumeGainDB: Double = 3.0 // e.g. -20 dB to +20 dB
    
    // 4. Fade effects options
    public var fadeInDuration: Double = 2.0 // seconds
    public var fadeOutDuration: Double = 2.0 // seconds
    
    public init() {}
}

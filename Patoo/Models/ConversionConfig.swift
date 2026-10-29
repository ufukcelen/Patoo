//
//  ConversionConfig.swift
//  Patoo
//

import Foundation

public enum ContainerFormat: String, CaseIterable, Identifiable, Sendable {
    case mp4 = "mp4"
    case mov = "mov"
    case mkv = "mkv"
    case webm = "webm"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        rawValue.uppercased()
    }
    
    public var defaultVideoCodec: VideoCodec {
        switch self {
        case .mp4, .mov: return .h264
        case .mkv: return .h265
        case .webm: return .vp9
        }
    }
    
    public var supportedVideoCodecs: [VideoCodec] {
        switch self {
        case .mp4:
            return [.h264, .h264Hardware, .h265, .h265Hardware, .copy]
        case .mov:
            return [.h264, .h264Hardware, .h265, .h265Hardware, .prores, .copy]
        case .mkv:
            return [.h264, .h265, .vp9, .copy]
        case .webm:
            return [.vp9]
        }
    }
}

public enum VideoCodec: String, CaseIterable, Identifiable, Sendable {
    case h264 = "libx264"
    case h264Hardware = "h264_videotoolbox"
    case h265 = "libx265"
    case h265Hardware = "hevc_videotoolbox"
    case prores = "prores_ks"
    case vp9 = "libvpx-vp9"
    case copy = "copy"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .h264: return "H.264 / AVC (CPU)"
        case .h264Hardware: return "H.264 (Apple Silicon H/W)"
        case .h265: return "HEVC / H.265 (CPU)"
        case .h265Hardware: return "HEVC / H.265 (Apple Silicon H/W)"
        case .prores: return "Apple ProRes"
        case .vp9: return "VP9"
        case .copy: return "Orijinal Akışı Koru (Kopyala)"
        }
    }
    
    public var isHardwareAccelerated: Bool {
        self == .h264Hardware || self == .h265Hardware
    }
}

public enum AudioCodec: String, CaseIterable, Identifiable, Sendable {
    case aac = "aac"
    case mp3 = "libmp3lame"
    case opus = "libopus"
    case flac = "flac"
    case copy = "copy"
    case none = "an"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .aac: return "AAC (Standart)"
        case .mp3: return "MP3"
        case .opus: return "Opus"
        case .flac: return "FLAC (Kayıpsız)"
        case .copy: return "Orijinal Sesi Koru (Kopyala)"
        case .none: return "Sessiz (Ses Yok)"
        }
    }
}

public enum TargetResolution: String, CaseIterable, Identifiable, Sendable {
    case original = "original"
    case uhd4k = "3840:2160"
    case fhd1080p = "1920:1080"
    case hd720p = "1280:720"
    case sd480p = "854:480"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .original: return "Orijinal Çözünürlük"
        case .uhd4k: return "4K UHD (3840×2160)"
        case .fhd1080p: return "1080p Full HD (1920×1080)"
        case .hd720p: return "720p HD (1280×720)"
        case .sd480p: return "480p SD (854×480)"
        }
    }
    
    public var ffmpegScaleFilter: String? {
        switch self {
        case .original:
            return nil
        case .uhd4k:
            return "scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2"
        case .fhd1080p:
            return "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"
        case .hd720p:
            return "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2"
        case .sd480p:
            return "scale=854:480:force_original_aspect_ratio=decrease,pad=854:480:(ow-iw)/2:(oh-ih)/2"
        }
    }
}

public enum TargetFrameRate: String, CaseIterable, Identifiable, Sendable {
    case original = "original"
    case fps24 = "24"
    case fps25 = "25"
    case fps30 = "30"
    case fps60 = "60"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .original: return "Orijinal FPS"
        case .fps24: return "24 fps (Sinema)"
        case .fps25: return "25 fps (PAL)"
        case .fps30: return "30 fps (Standart)"
        case .fps60: return "60 fps (Akıcı)"
        }
    }
}

public struct ConversionConfig: Sendable, Equatable {
    public var container: ContainerFormat = .mp4
    public var videoCodec: VideoCodec = .h264Hardware
    public var audioCodec: AudioCodec = .aac
    public var resolution: TargetResolution = .original
    public var frameRate: TargetFrameRate = .original
    public var crf: Int = 22
    public var audioBitrateKbps: Int = 192
    
    public init() {}
}

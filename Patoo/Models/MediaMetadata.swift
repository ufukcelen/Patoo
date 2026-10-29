//
//  MediaMetadata.swift
//  Patoo
//

import Foundation

// MARK: - FFprobe Root Model
public struct FFprobeOutput: Codable, Sendable {
    public let format: FFprobeFormat?
    public let streams: [FFprobeStream]?
}

public struct FFprobeFormat: Codable, Sendable {
    public let filename: String?
    public let nbStreams: Int?
    public let formatName: String?
    public let formatLongName: String?
    public let duration: String?
    public let size: String?
    public let bitRate: String?
    
    enum CodingKeys: String, CodingKey {
        case filename
        case nbStreams = "nb_streams"
        case formatName = "format_name"
        case formatLongName = "format_long_name"
        case duration
        case size
        case bitRate = "bit_rate"
    }
}

public struct FFprobeStream: Codable, Sendable, Identifiable {
    public var id: Int { index ?? 0 }
    
    public let index: Int?
    public let codecName: String?
    public let codecLongName: String?
    public let codecType: String? // "video", "audio", "subtitle"
    public let width: Int?
    public let height: Int?
    public let rFrameRate: String?
    public let avgFrameRate: String?
    public let bitRate: String?
    public let duration: String?
    public let sampleRate: String?
    public let channels: Int?
    public let channelLayout: String?
    public let pixFmt: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case codecName = "codec_name"
        case codecLongName = "codec_long_name"
        case codecType = "codec_type"
        case width, height
        case rFrameRate = "r_frame_rate"
        case avgFrameRate = "avg_frame_rate"
        case bitRate = "bit_rate"
        case duration
        case sampleRate = "sample_rate"
        case channels
        case channelLayout = "channel_layout"
        case pixFmt = "pix_fmt"
    }
}

// MARK: - Parsed Domain Metadata
public struct MediaMetadata: Sendable, Equatable {
    public let fileURL: URL
    public let fileSize: Int64
    public let durationSeconds: Double
    public let containerFormat: String
    public let bitRate: Int64
    
    public let videoStreams: [VideoStreamInfo]
    public let audioStreams: [AudioStreamInfo]
    
    public var primaryVideo: VideoStreamInfo? {
        videoStreams.first
    }
    
    public var primaryAudio: AudioStreamInfo? {
        audioStreams.first
    }
    
    public var formattedDuration: String {
        Self.formatDuration(durationSeconds)
    }
    
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    public var formattedBitrate: String {
        guard bitRate > 0 else { return "N/A" }
        let kbps = Double(bitRate) / 1000.0
        if kbps >= 1000 {
            return String(format: "%.1f Mbps", kbps / 1000.0)
        } else {
            return String(format: "%.0f kbps", kbps)
        }
    }
    
    public static func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "00:00" }
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    public static func from(ffprobe: FFprobeOutput, fileURL: URL, fallbackFileSize: Int64 = 0) -> MediaMetadata {
        let sizeVal = Int64(ffprobe.format?.size ?? "") ?? fallbackFileSize
        let durationVal = Double(ffprobe.format?.duration ?? "") ?? 0.0
        let bitRateVal = Int64(ffprobe.format?.bitRate ?? "") ?? 0
        let container = ffprobe.format?.formatName ?? fileURL.pathExtension.uppercased()
        
        let streams = ffprobe.streams ?? []
        
        let videos = streams.filter { $0.codecType == "video" }.map { s in
            let fps = parseFrameRate(s.avgFrameRate ?? s.rFrameRate)
            return VideoStreamInfo(
                index: s.index ?? 0,
                codec: s.codecName ?? "unknown",
                codecLongName: s.codecLongName,
                width: s.width ?? 0,
                height: s.height ?? 0,
                fps: fps,
                pixelFormat: s.pixFmt,
                bitRate: Int64(s.bitRate ?? "") ?? 0
            )
        }
        
        let audios = streams.filter { $0.codecType == "audio" }.map { s in
            return AudioStreamInfo(
                index: s.index ?? 0,
                codec: s.codecName ?? "unknown",
                codecLongName: s.codecLongName,
                sampleRate: Int(s.sampleRate ?? "") ?? 44100,
                channels: s.channels ?? 2,
                channelLayout: s.channelLayout ?? "stereo",
                bitRate: Int64(s.bitRate ?? "") ?? 0
            )
        }
        
        return MediaMetadata(
            fileURL: fileURL,
            fileSize: sizeVal,
            durationSeconds: durationVal,
            containerFormat: container,
            bitRate: bitRateVal,
            videoStreams: videos,
            audioStreams: audios
        )
    }
    
    private static func parseFrameRate(_ fpsStr: String?) -> Double {
        guard let fpsStr = fpsStr, !fpsStr.isEmpty else { return 0 }
        let parts = fpsStr.split(separator: "/")
        if parts.count == 2,
           let num = Double(parts[0]),
           let den = Double(parts[1]), den > 0 {
            return num / den
        }
        return Double(fpsStr) ?? 0
    }
}

public struct VideoStreamInfo: Sendable, Equatable, Identifiable {
    public var id: Int { index }
    public let index: Int
    public let codec: String
    public let codecLongName: String?
    public let width: Int
    public let height: Int
    public let fps: Double
    public let pixelFormat: String?
    public let bitRate: Int64
    
    public var resolutionString: String {
        guard width > 0 && height > 0 else { return "N/A" }
        return "\(width)x\(height)"
    }
    
    public var fpsString: String {
        guard fps > 0 else { return "N/A" }
        if fps.rounded() == fps {
            return String(format: "%.0f fps", fps)
        } else {
            return String(format: "%.2f fps", fps)
        }
    }
    
    public var summary: String {
        "\(codec.uppercased()) • \(resolutionString) • \(fpsString)"
    }
}

public struct AudioStreamInfo: Sendable, Equatable, Identifiable {
    public var id: Int { index }
    public let index: Int
    public let codec: String
    public let codecLongName: String?
    public let sampleRate: Int
    public let channels: Int
    public let channelLayout: String
    public let bitRate: Int64
    
    public var sampleRateString: String {
        "\(sampleRate / 1000) kHz"
    }
    
    public var channelsString: String {
        if channels == 1 { return "Mono" }
        if channels == 2 { return "Stereo" }
        if channels == 6 { return "5.1 Surround" }
        return "\(channels) ch"
    }
    
    public var summary: String {
        "\(codec.uppercased()) • \(sampleRateString) • \(channelsString)"
    }
}

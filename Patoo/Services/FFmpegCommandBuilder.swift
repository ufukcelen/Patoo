//
//  FFmpegCommandBuilder.swift
//  Patoo
//

import Foundation

public struct FFmpegCommand: Sendable, Equatable {
    public let arguments: [String]
    public let outputURL: URL
    
    public init(arguments: [String], outputURL: URL) {
        self.arguments = arguments
        self.outputURL = outputURL
    }
    
    public var commandDescription: String {
        "ffmpeg " + arguments.map { arg in
            if arg.contains(" ") || arg.contains(":") || arg.contains("=") {
                return "\"\(arg)\""
            }
            return arg
        }.joined(separator: " ")
    }
}

public enum FFmpegCommandBuilder {
    
    // MARK: - Video Conversion
    public static func buildConvertCommand(
        inputURL: URL,
        outputURL: URL,
        config: ConversionConfig
    ) -> FFmpegCommand {
        var args: [String] = [
            "-hide_banner",
            "-nostdin",
            "-progress", "pipe:1",
            "-y",
            "-i", inputURL.path
        ]
        
        let isAppleContainer = (config.container == .mp4 || config.container == .mov)
        
        // Video codec & filters
        switch config.videoCodec {
        case .copy:
            args.append(contentsOf: ["-c:v", "copy"])
            if isAppleContainer {
                // If copying into MP4/MOV, ensure hvc1 tag for HEVC compatibility with QuickTime
                args.append(contentsOf: ["-tag:v", "hvc1"])
            }
        case .h264Hardware:
            args.append(contentsOf: [
                "-c:v", "h264_videotoolbox",
                "-b:v", "5000k",
                "-pix_fmt", "yuv420p"
            ])
        case .h265Hardware:
            args.append(contentsOf: [
                "-c:v", "hevc_videotoolbox",
                "-b:v", "3500k",
                "-tag:v", "hvc1",
                "-pix_fmt", "yuv420p"
            ])
        case .h264:
            args.append(contentsOf: [
                "-c:v", "libx264",
                "-crf", "\(config.crf)",
                "-preset", "medium",
                "-pix_fmt", "yuv420p"
            ])
        case .h265:
            args.append(contentsOf: [
                "-c:v", "libx265",
                "-crf", "\(config.crf + 2)",
                "-preset", "medium",
                "-tag:v", "hvc1",
                "-pix_fmt", "yuv420p"
            ])
        case .prores:
            args.append(contentsOf: [
                "-c:v", "prores_ks",
                "-profile:v", "3", // ProRes 422 HQ
                "-pix_fmt", "yuv422p10le"
            ])
        case .vp9:
            args.append(contentsOf: [
                "-c:v", "libvpx-vp9",
                "-crf", "\(config.crf + 8)",
                "-b:v", "0"
            ])
        }
        
        // Video filters (resolution)
        if config.videoCodec != .copy, let scaleFilter = config.resolution.ffmpegScaleFilter {
            args.append(contentsOf: ["-vf", scaleFilter])
        }
        
        // Framerate
        if config.videoCodec != .copy && config.frameRate != .original {
            args.append(contentsOf: ["-r", config.frameRate.rawValue])
        }
        
        // Audio codec
        switch config.audioCodec {
        case .none:
            args.append("-an")
        case .copy:
            args.append(contentsOf: ["-c:a", "copy"])
        case .aac:
            args.append(contentsOf: ["-c:a", "aac", "-b:a", "\(config.audioBitrateKbps)k"])
        case .mp3:
            args.append(contentsOf: ["-c:a", "libmp3lame", "-b:a", "\(config.audioBitrateKbps)k"])
        case .opus:
            args.append(contentsOf: ["-c:a", "libopus", "-b:a", "\(config.audioBitrateKbps)k"])
        case .flac:
            args.append(contentsOf: ["-c:a", "flac"])
        }
        
        // Faststart for MP4 and MOV containers (moves moov atom to beginning for QuickTime & web playback)
        if isAppleContainer {
            args.append(contentsOf: ["-movflags", "+faststart"])
        }
        
        args.append(outputURL.path)
        return FFmpegCommand(arguments: args, outputURL: outputURL)
    }
    
    // MARK: - Video Compression
    public static func buildCompressCommand(
        inputURL: URL,
        outputURL: URL,
        config: CompressionConfig
    ) -> FFmpegCommand {
        var args: [String] = [
            "-hide_banner",
            "-nostdin",
            "-progress", "pipe:1",
            "-y",
            "-i", inputURL.path
        ]
        
        let crf = config.effectiveCRF
        
        if config.useHardwareAcceleration {
            // Apple Silicon VideoToolbox
            let videoBitrate: String
            switch config.profile {
            case .small: videoBitrate = "2000k"
            case .balanced: videoBitrate = "4000k"
            case .highQuality: videoBitrate = "8000k"
            case .custom: videoBitrate = "4500k"
            }
            args.append(contentsOf: [
                "-c:v", "h264_videotoolbox",
                "-b:v", videoBitrate,
                "-pix_fmt", "yuv420p"
            ])
        } else {
            // High efficiency software libx264
            args.append(contentsOf: [
                "-c:v", "libx264",
                "-crf", "\(crf)",
                "-preset", "medium",
                "-pix_fmt", "yuv420p"
            ])
        }
        
        // Optional downscale
        if config.downscaleTo1080pIfLarger {
            args.append(contentsOf: ["-vf", "scale='min(1920,iw)':-2"])
        }
        
        // Audio compression
        let audioBitrate = config.profile.defaultAudioBitrate
        args.append(contentsOf: [
            "-c:a", "aac",
            "-b:a", "\(audioBitrate)k"
        ])
        
        // Faststart for QuickTime compatibility & web streaming
        args.append(contentsOf: ["-movflags", "+faststart"])
        
        args.append(outputURL.path)
        return FFmpegCommand(arguments: args, outputURL: outputURL)
    }
    
    // MARK: - Audio Extraction
    public static func buildAudioExtractCommand(
        inputURL: URL,
        outputURL: URL,
        config: AudioExtractionConfig,
        sourceAudioCodec: String? = nil
    ) -> FFmpegCommand {
        var args: [String] = [
            "-hide_banner",
            "-nostdin",
            "-progress", "pipe:1",
            "-y",
            "-i", inputURL.path,
            "-vn" // Discard video stream
        ]
        
        // Check for passthrough compatibility
        let isPassthroughCompatible: Bool = {
            guard config.tryPassthroughIfCompatible, let sourceCodec = sourceAudioCodec?.lowercased() else {
                return false
            }
            if config.format == .aac && (sourceCodec == "aac") { return true }
            if config.format == .mp3 && (sourceCodec == "mp3") { return true }
            if config.format == .flac && (sourceCodec == "flac") { return true }
            return false
        }()
        
        if isPassthroughCompatible {
            args.append(contentsOf: ["-c:a", "copy"])
        } else {
            args.append(contentsOf: ["-c:a", config.format.defaultCodec])
            if config.format.supportsBitrateSelection {
                args.append(contentsOf: ["-b:a", "\(config.bitrate.rawValue)k"])
            }
        }
        
        args.append(outputURL.path)
        return FFmpegCommand(arguments: args, outputURL: outputURL)
    }
    
    // MARK: - Safe Target URL Generation
    public static func generateSafeTargetURL(
        sourceURL: URL,
        destinationDirectory: URL? = nil,
        customFileName: String? = nil,
        suffix: String? = "converted",
        targetExtension: String,
        overwrite: Bool = false
    ) -> URL {
        let dir = destinationDirectory ?? sourceURL.deletingLastPathComponent()
        let cleanExt = targetExtension.replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)
        
        let rawName: String
        if let custom = customFileName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            if custom.lowercased().hasSuffix("." + cleanExt.lowercased()) {
                rawName = String(custom.dropLast(cleanExt.count + 1))
            } else {
                rawName = custom
            }
        } else {
            let baseName = sourceURL.deletingPathExtension().lastPathComponent
            if let suf = suffix, !suf.isEmpty {
                rawName = "\(baseName)_\(suf)"
            } else {
                rawName = baseName
            }
        }
        
        var target = dir.appendingPathComponent("\(rawName).\(cleanExt)")
        
        if overwrite || !FileManager.default.fileExists(atPath: target.path) {
            return target
        }
        
        var counter = 1
        while FileManager.default.fileExists(atPath: target.path) {
            target = dir.appendingPathComponent("\(rawName)_\(counter).\(cleanExt)")
            counter += 1
        }
        
        return target
    }
}

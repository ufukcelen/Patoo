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
        
        // QuickTime Player container compatibility
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
        
        let crf = config.profile == .custom ? config.customCRF : config.profile.defaultCRF
        
        if config.useHardwareAcceleration {
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
            args.append(contentsOf: [
                "-c:v", "libx264",
                "-crf", "\(crf)",
                "-preset", "medium",
                "-pix_fmt", "yuv420p"
            ])
        }
        
        if config.downscaleTo1080pIfLarger {
            args.append(contentsOf: ["-vf", "scale='min(1920,iw)':-2"])
        }
        
        let audioBitrate = config.profile.defaultAudioBitrate
        args.append(contentsOf: [
            "-c:a", "aac",
            "-b:a", "\(audioBitrate)k"
        ])
        
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
            "-vn"
        ]
        
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
    
    // MARK: - Audio Studio Operations
    public static func buildAudioStudioCommand(
        inputURL: URL,
        outputURL: URL,
        config: AudioStudioConfig,
        sourceMetadata: MediaMetadata? = nil
    ) -> FFmpegCommand {
        switch config.mode {
        case .extract:
            let primaryAudio = sourceMetadata?.primaryAudio?.codec
            return buildAudioExtractCommand(
                inputURL: inputURL,
                outputURL: outputURL,
                config: config.extractionConfig,
                sourceAudioCodec: primaryAudio
            )
            
        case .removeAudio:
            let args = [
                "-hide_banner",
                "-nostdin",
                "-progress", "pipe:1",
                "-y",
                "-i", inputURL.path,
                "-c:v", "copy",
                "-an",
                "-movflags", "+faststart",
                outputURL.path
            ]
            return FFmpegCommand(arguments: args, outputURL: outputURL)
            
        case .normalize:
            let lufs = String(format: "%.1f", config.targetLUFS)
            let args = [
                "-hide_banner",
                "-nostdin",
                "-progress", "pipe:1",
                "-y",
                "-i", inputURL.path,
                "-c:v", "copy",
                "-af", "loudnorm=I=\(lufs):TP=-1.5:LRA=11",
                "-c:a", "aac",
                "-b:a", "256k",
                "-movflags", "+faststart",
                outputURL.path
            ]
            return FFmpegCommand(arguments: args, outputURL: outputURL)
            
        case .volume:
            let gain = config.volumeGainDB >= 0 ? "+\(String(format: "%.1f", config.volumeGainDB))dB" : "\(String(format: "%.1f", config.volumeGainDB))dB"
            let args = [
                "-hide_banner",
                "-nostdin",
                "-progress", "pipe:1",
                "-y",
                "-i", inputURL.path,
                "-c:v", "copy",
                "-af", "volume=\(gain)",
                "-c:a", "aac",
                "-b:a", "256k",
                "-movflags", "+faststart",
                outputURL.path
            ]
            return FFmpegCommand(arguments: args, outputURL: outputURL)
            
        case .fade:
            let duration = sourceMetadata?.durationSeconds ?? 60.0
            let fadeIn = config.fadeInDuration
            let fadeOut = config.fadeOutDuration
            let startOut = max(0, duration - fadeOut)
            let filter = "afade=t=in:ss=0:d=\(String(format: "%.1f", fadeIn)),afade=t=out:st=\(String(format: "%.1f", startOut)):d=\(String(format: "%.1f", fadeOut))"
            
            let args = [
                "-hide_banner",
                "-nostdin",
                "-progress", "pipe:1",
                "-y",
                "-i", inputURL.path,
                "-c:v", "copy",
                "-af", filter,
                "-c:a", "aac",
                "-b:a", "256k",
                "-movflags", "+faststart",
                outputURL.path
            ]
            return FFmpegCommand(arguments: args, outputURL: outputURL)
        }
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
        
        let baseName: String
        if let custom = customFileName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            let customURL = URL(fileURLWithPath: custom)
            if customURL.pathExtension.lowercased() == cleanExt.lowercased() {
                baseName = customURL.deletingPathExtension().lastPathComponent
            } else {
                baseName = custom
            }
        } else {
            let originalStem = sourceURL.deletingPathExtension().lastPathComponent
            if let s = suffix, !s.isEmpty {
                baseName = "\(originalStem)_\(s)"
            } else {
                baseName = originalStem
            }
        }
        
        let fileManager = FileManager.default
        let candidate = dir.appendingPathComponent("\(baseName).\(cleanExt)")
        
        if overwrite || !fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }
        
        var counter = 1
        while true {
            let indexedName = "\(baseName)_\(counter).\(cleanExt)"
            let indexedURL = dir.appendingPathComponent(indexedName)
            if !fileManager.fileExists(atPath: indexedURL.path) {
                return indexedURL
            }
            counter += 1
        }
    }
}

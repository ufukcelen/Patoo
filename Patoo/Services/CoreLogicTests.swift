//
//  CoreLogicTests.swift
//  Patoo
//

import Foundation

public enum CoreLogicTests {
    @discardableResult
    public static func runAllTests() -> Bool {
        print("[PatooTests] Başlatılıyor...")
        
        // Test 1: Duration formatting
        assert(MediaMetadata.formatDuration(0) == "00:00", "0 duration should be 00:00")
        assert(MediaMetadata.formatDuration(65) == "01:05", "65s should be 01:05")
        assert(MediaMetadata.formatDuration(3665) == "01:01:05", "3665s should be 01:01:05")
        print("[PatooTests] Duration formatting: OK")
        
        // Test 2: Safe target URL generation (with suffix and custom name)
        let sampleURL = URL(fileURLWithPath: "/tmp/video.mov")
        let target1 = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: sampleURL,
            suffix: "converted",
            targetExtension: "mp4",
            overwrite: false
        )
        assert(target1.lastPathComponent == "video_converted.mp4", "Target URL mismatch")
        
        // Test 2b: Custom file name (e.g., user specifies "b" for "a.mp4" -> "b.mkv")
        let targetCustom1 = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: sampleURL,
            customFileName: "b",
            suffix: "converted",
            targetExtension: "mkv",
            overwrite: false
        )
        assert(targetCustom1.lastPathComponent == "b.mkv", "Custom name 'b' should produce 'b.mkv'")
        
        // Test 2c: Custom file name with typed extension "b.mkv"
        let targetCustom2 = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: sampleURL,
            customFileName: "b.mkv",
            suffix: "converted",
            targetExtension: "mkv",
            overwrite: false
        )
        assert(targetCustom2.lastPathComponent == "b.mkv", "Custom name 'b.mkv' should strip duplicate extension and produce 'b.mkv'")
        print("[PatooTests] Safe target URL & Custom file names: OK")
        
        // Test 3: Conversion command builder & QuickTime compatibility flags
        var convConfig = ConversionConfig()
        convConfig.container = .mp4
        convConfig.videoCodec = .h264
        convConfig.crf = 21
        convConfig.resolution = .fhd1080p
        convConfig.frameRate = .fps30
        convConfig.audioCodec = .aac
        
        let convCmd = FFmpegCommandBuilder.buildConvertCommand(
            inputURL: sampleURL,
            outputURL: target1,
            config: convConfig
        )
        assert(convCmd.arguments.contains("-c:v"), "Missing -c:v")
        assert(convCmd.arguments.contains("libx264"), "Missing libx264")
        assert(convCmd.arguments.contains("-crf"), "Missing -crf")
        assert(convCmd.arguments.contains("21"), "Missing crf 21")
        assert(convCmd.arguments.contains("-pix_fmt"), "Missing -pix_fmt")
        assert(convCmd.arguments.contains("yuv420p"), "Missing yuv420p for QuickTime compatibility")
        assert(convCmd.arguments.contains("-movflags"), "Missing -movflags")
        assert(convCmd.arguments.contains("+faststart"), "Missing +faststart for QuickTime compatibility")
        assert(convCmd.arguments.contains("-vf"), "Missing -vf")
        assert(convCmd.arguments.contains("-r"), "Missing -r")
        assert(convCmd.arguments.contains("30"), "Missing fps 30")
        assert(convCmd.arguments.contains("-c:a"), "Missing -c:a")
        assert(convCmd.arguments.contains("aac"), "Missing aac")
        
        // Test 3b: HEVC Apple compatibility (hvc1 tag)
        var hevcConfig = ConversionConfig()
        hevcConfig.container = .mp4
        hevcConfig.videoCodec = .h265Hardware
        let hevcCmd = FFmpegCommandBuilder.buildConvertCommand(
            inputURL: sampleURL,
            outputURL: target1,
            config: hevcConfig
        )
        assert(hevcCmd.arguments.contains("-tag:v"), "HEVC must include -tag:v for QuickTime")
        assert(hevcCmd.arguments.contains("hvc1"), "HEVC must be tagged as hvc1 for Apple QuickTime")
        print("[PatooTests] Conversion command builder: OK")
        
        // Test 4: Compression command builder
        var compConfig = CompressionConfig()
        compConfig.profile = .small
        compConfig.useHardwareAcceleration = false
        compConfig.downscaleTo1080pIfLarger = true
        
        let compCmd = FFmpegCommandBuilder.buildCompressCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/video_compressed.mp4"),
            config: compConfig
        )
        assert(compCmd.arguments.contains("28"), "Small profile should use CRF 28")
        assert(compCmd.arguments.contains("-pix_fmt"), "Compression missing -pix_fmt")
        assert(compCmd.arguments.contains("yuv420p"), "Compression missing yuv420p")
        assert(compCmd.arguments.contains("+faststart"), "Compression missing faststart")
        assert(compCmd.arguments.contains("scale='min(1920,iw)':-2"), "Downscale filter missing")
        print("[PatooTests] Compression command builder: OK")
        
        // Test 5: Audio extraction command builder
        var audioConfig = AudioExtractionConfig()
        audioConfig.format = .mp3
        audioConfig.bitrate = .kbps320
        audioConfig.tryPassthroughIfCompatible = true
        
        let audioCmd = FFmpegCommandBuilder.buildAudioExtractCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/audio.mp3"),
            config: audioConfig,
            sourceAudioCodec: "aac" // Not compatible with MP3, so should encode
        )
        assert(audioCmd.arguments.contains("-vn"), "Missing -vn")
        assert(audioCmd.arguments.contains("libmp3lame"), "Missing libmp3lame")
        assert(audioCmd.arguments.contains("320k"), "Missing 320k")
        
        // Passthrough compatibility test
        let passthroughCmd = FFmpegCommandBuilder.buildAudioExtractCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/audio.mp3"),
            config: audioConfig,
            sourceAudioCodec: "mp3" // Compatible!
        )
        assert(passthroughCmd.arguments.contains("copy"), "Should use stream copy for matching mp3")
        print("[PatooTests] Audio extraction command builder: OK")
        
        // Test 6: Progress Parser
        let parser = FFmpegProgressParser(totalDurationSeconds: 60.0)
        let chunk = """
        frame=300
        fps=60.0
        stream_0_0_q=28.0
        bitrate=1500.0kbits/s
        total_size=11250000
        out_time_us=30000000
        out_time_ms=30000000
        out_time=00:00:30.000000
        dup_frames=0
        drop_frames=0
        speed=2.50x
        progress=continue
        """
        let snapshots = parser.parseLineChunk(chunk)
        assert(!snapshots.isEmpty, "Parser should produce snapshots")
        if let last = snapshots.last {
            assert(abs(last.progress - 0.5) < 0.05, "Progress should be around 50%")
            assert(last.speed == "2.50x", "Speed mismatch")
            assert(last.fps == "60.0", "FPS mismatch")
        }
        print("[PatooTests] Progress parser: OK")
        
        // Test 7: FFprobe JSON Decoding
        let mockJSON = """
        {
            "format": {
                "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
                "duration": "120.5",
                "size": "15000000",
                "bit_rate": "1000000"
            },
            "streams": [
                {
                    "index": 0,
                    "codec_name": "h264",
                    "codec_type": "video",
                    "width": 1920,
                    "height": 1080,
                    "avg_frame_rate": "30/1"
                },
                {
                    "index": 1,
                    "codec_name": "aac",
                    "codec_type": "audio",
                    "sample_rate": "48000",
                    "channels": 2
                }
            ]
        }
        """.data(using: .utf8)!
        
        do {
            let decoded = try JSONDecoder().decode(FFprobeOutput.self, from: mockJSON)
            let meta = MediaMetadata.from(ffprobe: decoded, fileURL: sampleURL)
            assert(meta.durationSeconds == 120.5, "Duration mismatch")
            assert(meta.videoStreams.count == 1, "Expected 1 video stream")
            assert(meta.audioStreams.count == 1, "Expected 1 audio stream")
            assert(meta.primaryVideo?.resolutionString == "1920x1080", "Resolution mismatch")
            assert(meta.primaryAudio?.codec == "aac", "Audio codec mismatch")
            print("[PatooTests] FFprobe JSON decoding: OK")
        } catch {
            assertionFailure("Failed to decode mock FFprobe JSON: \(error)")
        }
        
        print("[PatooTests] TÜM TESTLER BAŞARIYLA TAMAMLANDI! ✅")
        return true
    }
}

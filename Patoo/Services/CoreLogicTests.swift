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
        
        // Test 2: Safe target URL generation
        let sampleURL = URL(fileURLWithPath: "/tmp/video.mov")
        let target1 = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: sampleURL,
            suffix: "converted",
            targetExtension: "mp4",
            overwrite: false
        )
        assert(target1.lastPathComponent == "video_converted.mp4", "Target URL mismatch")
        print("[PatooTests] Safe target URL: OK")
        
        // Test 3: Conversion command builder
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
        assert(convCmd.arguments.contains("-vf"), "Missing -vf")
        assert(convCmd.arguments.contains("-r"), "Missing -r")
        assert(convCmd.arguments.contains("30"), "Missing fps 30")
        assert(convCmd.arguments.contains("-c:a"), "Missing -c:a")
        assert(convCmd.arguments.contains("aac"), "Missing aac")
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
        stream_0_0_q=23.0
        bitrate=4500.0kbits/s
        total_size=1234567
        out_time_us=30000000
        speed=2.0x
        progress=continue
        """
        let snapshots = parser.parseLineChunk(chunk)
        assert(snapshots.count == 1, "Should parse 1 snapshot")
        let s = snapshots[0]
        assert(abs(s.progress - 0.5) < 0.01, "Progress should be 50%")
        assert(s.speed == "2.0x", "Speed should be 2.0x")
        assert(s.fps == "60.0", "FPS should be 60.0")
        assert(s.estimatedRemainingSeconds != nil, "Remaining seconds should be calculated")
        print("[PatooTests] Progress parser: OK")
        
        // Test 7: FFprobe JSON Decoding
        let dummyJSON = """
        {
          "format": {
            "filename": "test.mp4",
            "duration": "12.500000",
            "size": "5242880",
            "bit_rate": "3355443",
            "format_name": "mov,mp4,m4a,3gp,3g2,mj2"
          },
          "streams": [
            {
              "index": 0,
              "codec_name": "h264",
              "codec_type": "video",
              "width": 1920,
              "height": 1080,
              "r_frame_rate": "30/1",
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
        
        let decoded = try! JSONDecoder().decode(FFprobeOutput.self, from: dummyJSON)
        let meta = MediaMetadata.from(ffprobe: decoded, fileURL: URL(fileURLWithPath: "/tmp/test.mp4"))
        assert(meta.videoStreams.count == 1, "Should have 1 video stream")
        assert(meta.primaryVideo?.resolutionString == "1920x1080", "Resolution mismatch")
        assert(meta.audioStreams.count == 1, "Should have 1 audio stream")
        assert(meta.formattedDuration == "00:13", "Formatted duration mismatch")
        print("[PatooTests] FFprobe JSON decoding: OK")
        
        print("[PatooTests] TÜM TESTLER BAŞARIYLA TAMAMLANDI! ✅")
        return true
    }
}

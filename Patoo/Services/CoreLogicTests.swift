//
//  CoreLogicTests.swift
//  Patoo
//

import Foundation

public enum CoreLogicTests {
    public static func runAllTests() {
        print("[PatooTests] Başlatılıyor...")
        
        // Test 1: Duration formatting
        assert(MediaMetadata.formatDuration(0) == "00:00")
        assert(MediaMetadata.formatDuration(65) == "01:05")
        assert(MediaMetadata.formatDuration(3665) == "01:01:05")
        print("[PatooTests] Duration formatting: OK")
        
        // Test 2: Safe target URL generation & Custom File Names
        let sampleURL = URL(fileURLWithPath: "/tmp/sample_video.mp4")
        let target1 = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: sampleURL,
            destinationDirectory: URL(fileURLWithPath: "/tmp"),
            suffix: "test",
            targetExtension: "mkv"
        )
        assert(target1.lastPathComponent.contains("sample_video_test"))
        assert(target1.pathExtension == "mkv")
        
        // Custom name "b" -> "/tmp/b.mkv"
        let customTargetB = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: sampleURL,
            destinationDirectory: URL(fileURLWithPath: "/tmp"),
            customFileName: "b",
            suffix: "converted",
            targetExtension: "mkv"
        )
        assert(customTargetB.pathExtension == "mkv")
        assert(customTargetB.deletingPathExtension().lastPathComponent.hasPrefix("b"))
        
        // Custom name with redundant extension "b.mkv" -> should not produce "b.mkv.mkv"
        let customTargetWithExt = FFmpegCommandBuilder.generateSafeTargetURL(
            sourceURL: sampleURL,
            destinationDirectory: URL(fileURLWithPath: "/tmp"),
            customFileName: "b.mkv",
            suffix: "converted",
            targetExtension: "mkv"
        )
        assert(customTargetWithExt.pathExtension == "mkv")
        assert(!customTargetWithExt.lastPathComponent.contains("mkv.mkv"))
        print("[PatooTests] Safe target URL & Custom file names: OK")
        
        // Test 3: Conversion command builder & QuickTime compatibility
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
            sourceAudioCodec: "aac"
        )
        assert(audioCmd.arguments.contains("-vn"), "Missing -vn")
        assert(audioCmd.arguments.contains("libmp3lame"), "Missing libmp3lame")
        assert(audioCmd.arguments.contains("320k"), "Missing 320k")
        
        let passthroughCmd = FFmpegCommandBuilder.buildAudioExtractCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/audio.mp3"),
            config: audioConfig,
            sourceAudioCodec: "mp3"
        )
        assert(passthroughCmd.arguments.contains("copy"), "Should use stream copy for matching mp3")
        print("[PatooTests] Audio extraction command builder: OK")
        
        // Test 6: Audio Studio (Mute, Normalize, Volume, Fade)
        var muteConfig = AudioStudioConfig()
        muteConfig.mode = .removeAudio
        let muteCmd = FFmpegCommandBuilder.buildAudioStudioCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/muted.mp4"),
            config: muteConfig
        )
        assert(muteCmd.arguments.contains("-an"), "Audio studio removeAudio must contain -an")
        assert(muteCmd.arguments.contains("-c:v") && muteCmd.arguments.contains("copy"), "Audio studio removeAudio must copy video stream")
        
        var normConfig = AudioStudioConfig()
        normConfig.mode = .normalize
        normConfig.targetLUFS = -16.0
        let normCmd = FFmpegCommandBuilder.buildAudioStudioCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/norm.mp4"),
            config: normConfig
        )
        assert(normCmd.arguments.contains("-af"), "Normalize must contain audio filter")
        assert(normCmd.arguments.contains("loudnorm=I=-16.0:TP=-1.5:LRA=11"), "Normalize filter syntax mismatch")
        
        var volConfig = AudioStudioConfig()
        volConfig.mode = .volume
        volConfig.volumeGainDB = 4.0
        let volCmd = FFmpegCommandBuilder.buildAudioStudioCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/vol.mp4"),
            config: volConfig
        )
        assert(volCmd.arguments.contains("volume=+4.0dB"), "Volume gain filter mismatch")
        
        var fadeConfig = AudioStudioConfig()
        fadeConfig.mode = .fade
        fadeConfig.fadeInDuration = 3.0
        fadeConfig.fadeOutDuration = 2.0
        let meta = MediaMetadata(
            fileURL: sampleURL,
            fileSize: 1024,
            durationSeconds: 30.0,
            containerFormat: "mp4",
            bitRate: 1000,
            videoStreams: [],
            audioStreams: []
        )
        let fadeCmd = FFmpegCommandBuilder.buildAudioStudioCommand(
            inputURL: sampleURL,
            outputURL: URL(fileURLWithPath: "/tmp/fade.mp4"),
            config: fadeConfig,
            sourceMetadata: meta
        )
        assert(fadeCmd.arguments.contains("afade=t=in:ss=0:d=3.0,afade=t=out:st=28.0:d=2.0"), "Fade filter syntax mismatch")
        print("[PatooTests] Audio Studio commands: OK")
        
        // Test 7: Progress Parser
        let parser = FFmpegProgressParser(totalDurationSeconds: 60.0)
        let chunk = """
        frame=300
        fps=60.0
        stream_0_0_q=28.0
        bitrate=1500.0kbits/s
        total_size=12000000
        out_time_us=30000000
        out_time_ms=30000000
        out_time=00:00:30.000000
        dup_frames=0
        drop_frames=0
        speed=2.50x
        progress=continue
        """
        if let snapshot = parser.parseLineChunk(chunk).first {
            assert(snapshot.progress >= 0.49 && snapshot.progress <= 0.51, "Progress should be ~0.50, got \(snapshot.progress)")
            assert(snapshot.speed == "2.50x", "Speed should be 2.50x")
            assert(snapshot.fps == "60.0", "FPS should be 60.0")
        } else {
            assertionFailure("Progress chunk parsing failed")
        }
        print("[PatooTests] Progress parser: OK")
        
        // Test 8: FFprobe JSON Decoding
        let sampleJSON = """
        {
            "format": {
                "filename": "/tmp/test.mp4",
                "nb_streams": 2,
                "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
                "format_long_name": "QuickTime / MOV",
                "duration": "12.345",
                "size": "5678901",
                "bit_rate": "3681531"
            },
            "streams": [
                {
                    "index": 0,
                    "codec_name": "h264",
                    "codec_long_name": "H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10",
                    "codec_type": "video",
                    "width": 1920,
                    "height": 1080,
                    "avg_frame_rate": "30/1",
                    "bit_rate": "3500000",
                    "pix_fmt": "yuv420p"
                },
                {
                    "index": 1,
                    "codec_name": "aac",
                    "codec_long_name": "AAC (Advanced Audio Coding)",
                    "codec_type": "audio",
                    "sample_rate": "48000",
                    "channels": 2,
                    "channel_layout": "stereo",
                    "bit_rate": "181531"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let ffprobeOutput = try! JSONDecoder().decode(FFprobeOutput.self, from: sampleJSON)
        let parsedMeta = MediaMetadata.from(ffprobe: ffprobeOutput, fileURL: sampleURL)
        assert(parsedMeta.videoStreams.count == 1)
        assert(parsedMeta.audioStreams.count == 1)
        assert(parsedMeta.primaryVideo?.width == 1920)
        assert(parsedMeta.primaryVideo?.height == 1080)
        assert(parsedMeta.primaryAudio?.codec == "aac")
        assert(parsedMeta.primaryAudio?.channels == 2)
        print("[PatooTests] FFprobe JSON decoding: OK")
        
        // Test 9: FFmpeg Location & Version Extraction
        let sampleOutput1 = "ffmpeg version 7.1 Copyright (c) 2000-2024 the FFmpeg developers"
        let sampleOutput2 = "ffmpeg version 9.0.2-evermeet.cx"
        
        let pattern = #"version\s+([0-9]+(?:\.[0-9]+)*)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        if let match1 = regex.firstMatch(in: sampleOutput1, range: NSRange(sampleOutput1.startIndex..., in: sampleOutput1)),
           let r1 = Range(match1.range(at: 1), in: sampleOutput1) {
            assert(String(sampleOutput1[r1]) == "7.1")
        } else {
            assertionFailure("Regex version 7.1 failed")
        }
        
        if let match2 = regex.firstMatch(in: sampleOutput2, range: NSRange(sampleOutput2.startIndex..., in: sampleOutput2)),
           let r2 = Range(match2.range(at: 1), in: sampleOutput2) {
            assert(String(sampleOutput2[r2]) == "9.0.2")
        } else {
            assertionFailure("Regex version 9.0.2 failed")
        }
        print("[PatooTests] Version regex tests: OK")
        
        print("[PatooTests] TÜM TESTLER BAŞARIYLA TAMAMLANDI! ✅")
    }
}

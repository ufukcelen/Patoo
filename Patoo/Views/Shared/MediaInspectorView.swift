//
//  MediaInspectorView.swift
//  Patoo
//

import SwiftUI

public struct MediaInspectorView: View {
    public let metadata: MediaMetadata
    public var onRemove: (() -> Void)? = nil
    
    public init(metadata: MediaMetadata, onRemove: (() -> Void)? = nil) {
        self.metadata = metadata
        self.onRemove = onRemove
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PatooTheme.cyan.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: metadata.videoStreams.isEmpty ? "waveform" : "film")
                        .font(.system(size: 20))
                        .foregroundColor(PatooTheme.cyan)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(metadata.fileURL.lastPathComponent)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(metadata.formattedFileSize)
                        Text("•")
                        Text(metadata.formattedDuration)
                        Text("•")
                        Text(metadata.containerFormat.uppercased())
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(PatooTheme.textSecondary)
                }
                
                Spacer()
                
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(PatooTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Dosyayı kaldır")
                }
            }
            
            Divider()
                .background(PatooTheme.borderSubtle)
            
            // Technical Specs Grid
            HStack(spacing: 10) {
                if let video = metadata.primaryVideo {
                    TechnicalStatPill(title: "VIDEO CODEC", value: video.codec.uppercased(), icon: "film")
                    TechnicalStatPill(title: "ÇÖZÜNÜRLÜK", value: video.resolutionString, icon: "aspectratio")
                    TechnicalStatPill(title: "KARE HIZI", value: video.fpsString, icon: "speedometer")
                }
                
                if let audio = metadata.primaryAudio {
                    TechnicalStatPill(title: "SES CODEC", value: audio.codec.uppercased(), icon: "speaker.wave.2")
                    TechnicalStatPill(title: "KANAL", value: audio.channelsString, icon: "hifispeaker.2")
                } else if metadata.videoStreams.isEmpty == false {
                    TechnicalStatPill(title: "SES", value: "Ses Yok", icon: "speaker.slash")
                }
                
                if metadata.bitRate > 0 {
                    TechnicalStatPill(title: "BİT ORANI", value: metadata.formattedBitrate, icon: "chart.bar")
                }
            }
        }
        .padding(14)
        .patooCard(cornerRadius: 10)
    }
}

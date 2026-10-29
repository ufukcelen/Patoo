//
//  TrimPlaceholderView.swift
//  Patoo
//

import SwiftUI

public struct TrimPlaceholderView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(PatooTheme.cyan.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "scissors")
                    .font(.system(size: 36))
                    .foregroundColor(PatooTheme.cyan)
            }
            
            VStack(spacing: 6) {
                Text("Hassas Video Kırpma")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(PatooTheme.textPrimary)
                
                Text("Geliştirme Aşamasında • v0.1 Yol Haritası")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(PatooTheme.cyan)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Kırpma modülü için planlanan temel özellikler:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PatooTheme.textSecondary)
                
                FeatureBullet(text: "Kayıpsız kesme (Stream Copy ile yeniden kodlama yapmadan saniyeler içinde kesme)")
                FeatureBullet(text: "Kare hassasiyetinde I-Frame / Keyframe tespiti ve milisaniye bazlı zamanlayıcı")
                FeatureBullet(text: "Görsel zaman çizelgesi (Timeline Scrubber) ve video önizleme")
                FeatureBullet(text: "Gereksiz bölümleri atıp kalan parçaları tek bir dosyada birleştirme")
            }
            .frame(maxWidth: 460, alignment: .leading)
            .padding(20)
            .patooCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(PatooTheme.bgDark)
    }
}

private struct FeatureBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 12))
                .foregroundColor(PatooTheme.cyan)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(PatooTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

//
//  CompressionConfig.swift
//  Patoo
//

import Foundation

public enum CompressionProfile: String, CaseIterable, Identifiable, Sendable {
    case small = "small"
    case balanced = "balanced"
    case highQuality = "highQuality"
    case custom = "custom"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .small: return "Küçük Dosya"
        case .balanced: return "Dengeli"
        case .highQuality: return "Yüksek Kalite"
        case .custom: return "Özel"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .small: return "En yüksek sıkıştırma, web ve paylaşım için ideal (%50-%70 tasarruf)"
        case .balanced: return "Kalite ve boyut dengesi, genel kullanım için önerilir (%30-%50 tasarruf)"
        case .highQuality: return "Görsel kayıp minimum, arşivleme ve yüksek netlik için (%10-%25 tasarruf)"
        case .custom: return "CRF ve hedef çözünürlüğü el ile belirleyin"
        }
    }
    
    public var defaultCRF: Int {
        switch self {
        case .small: return 28
        case .balanced: return 23
        case .highQuality: return 18
        case .custom: return 23
        }
    }
    
    public var defaultAudioBitrate: Int {
        switch self {
        case .small: return 128
        case .balanced: return 192
        case .highQuality: return 256
        case .custom: return 192
        }
    }
    
    public var iconName: String {
        switch self {
        case .small: return "arrow.down.right.and.arrow.up.left"
        case .balanced: return "scalemass"
        case .highQuality: return "sparkles"
        case .custom: return "slider.horizontal.3"
        }
    }
}

public struct CompressionConfig: Sendable, Equatable {
    public var profile: CompressionProfile = .balanced
    public var customCRF: Int = 23
    public var downscaleTo1080pIfLarger: Bool = false
    public var useHardwareAcceleration: Bool = true
    public var audioBitrateKbps: Int = 192
    
    public init() {}
    
    public var effectiveCRF: Int {
        if profile == .custom {
            return customCRF
        }
        return profile.defaultCRF
    }
}

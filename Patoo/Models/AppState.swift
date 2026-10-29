//
//  AppState.swift
//  Patoo
//

import SwiftUI
import Observation

public enum NavigationSection: String, CaseIterable, Identifiable, Sendable {
    case overview = "overview"
    case convert = "convert"
    case compress = "compress"
    case audioStudio = "audioStudio"
    case batch = "batch"
    case mediaInfo = "mediaInfo"
    case queue = "queue"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .overview: return "Genel Bakış"
        case .convert: return "Dönüştürme"
        case .compress: return "Sıkıştırma"
        case .audioStudio: return "Ses Stüdyosu"
        case .batch: return "Toplu İşlemler"
        case .mediaInfo: return "Medya Bilgisi"
        case .queue: return "İşlem Kuyruğu"
        case .settings: return "Ayarlar"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .overview: return "Dosya ekleme, son işlemler, hızlı eylemler ve genel işlem durumu."
        case .convert: return "Çıktı formatı, codec, çözünürlük, FPS ve ses seçenekleri."
        case .compress: return "Kalite modu, hedef dosya boyutu, yaklaşık sonuç ve kalite karşılaştırması."
        case .audioStudio: return "Ses çıkarma, sesi kaldırma, normalizasyon, ses seviyesi ve fade efektleri."
        case .batch: return "Klasör seçimi, dosya başına ayarlar, kuyruk, duraklatma ve iptal."
        case .mediaInfo: return "Teknik özellikler, ses ve görüntü akışları, metadata ve ayrıntılı analiz."
        case .queue: return "Arka planda çalışan ve bekleyen tüm video ve ses işlemleri."
        case .settings: return "FFmpeg motoru, donanım optimizasyonları ve uygulama tercihleri."
        }
    }
    
    public var iconName: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .convert: return "arrow.triangle.2.circlepath"
        case .compress: return "gauge.with.needle"
        case .audioStudio: return "waveform"
        case .batch: return "square.stack.3d.up"
        case .mediaInfo: return "doc.text.magnifyingglass"
        case .queue: return "list.bullet.rectangle"
        case .settings: return "gearshape"
        }
    }
    
    public static let primarySections: [NavigationSection] = [.overview, .convert, .compress, .audioStudio, .batch, .mediaInfo]
    
    public var isPrimaryMenuItem: Bool {
        switch self {
        case .overview, .convert, .compress, .audioStudio, .batch, .mediaInfo:
            return true
        case .queue, .settings:
            return false
        }
    }
    
    public var isPinnable: Bool {
        return self != .overview
    }
}

public struct ToastMessage: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let message: String
    public let isError: Bool
    
    public init(message: String, isError: Bool = false) {
        self.message = message
        self.isError = isError
    }
}

@Observable
@MainActor
public final class AppState {
    public static let shared = AppState()
    
    public var selectedSection: NavigationSection = .overview
    public var ffmpegInstallation: FFmpegInstallation = .missing
    public var toast: ToastMessage? = nil
    
    // Pinned Quick Actions
    private let pinnedStorageKey = "patoo_pinned_quick_actions"
    public var pinnedSections: [NavigationSection] = []
    
    public init() {
        refreshInstallation()
        loadPinnedSections()
    }
    
    public func refreshInstallation() {
        self.ffmpegInstallation = FFmpegLocator.shared.locate()
    }
    
    public func loadPinnedSections() {
        if let stored = UserDefaults.standard.stringArray(forKey: pinnedStorageKey) {
            self.pinnedSections = stored.compactMap { NavigationSection(rawValue: $0) }
        } else {
            // Start empty by default as requested: "Genel bakış hızlı işlemler boş olacak"
            self.pinnedSections = []
        }
    }
    
    public func isPinned(_ section: NavigationSection) -> Bool {
        pinnedSections.contains(section)
    }
    
    public func togglePin(_ section: NavigationSection) {
        if let index = pinnedSections.firstIndex(of: section) {
            pinnedSections.remove(at: index)
            showToast("\(section.title) Hızlı İşlemlerden kaldırıldı")
        } else {
            pinnedSections.append(section)
            showToast("\(section.title) Hızlı İşlemlere sabitlendi 📌")
        }
        let rawValues = pinnedSections.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: pinnedStorageKey)
    }
    
    public func showToast(_ message: String, isError: Bool = false) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.toast = ToastMessage(message: message, isError: isError)
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.toast?.message == message {
                withAnimation {
                    self.toast = nil
                }
            }
        }
    }
}

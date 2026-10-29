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
    case trim = "trim"
    case audioExtract = "audioExtract"
    case queue = "queue"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .overview: return "Genel Bakış"
        case .convert: return "Dönüştür"
        case .compress: return "Sıkıştır"
        case .trim: return "Kırp"
        case .audioExtract: return "Ses Çıkar"
        case .queue: return "İşlem Kuyruğu"
        case .settings: return "Ayarlar"
        }
    }
    
    public var iconName: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .convert: return "arrow.triangle.2.circlepath"
        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .trim: return "scissors"
        case .audioExtract: return "waveform"
        case .queue: return "list.bullet.rectangle"
        case .settings: return "gearshape"
        }
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
    
    public init() {
        refreshInstallation()
    }
    
    public func refreshInstallation() {
        self.ffmpegInstallation = FFmpegLocator.shared.locate()
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

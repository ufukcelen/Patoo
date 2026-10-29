//
//  QueueView.swift
//  Patoo
//

import SwiftUI
import AppKit

public struct QueueView: View {
    var queueManager: QueueManager
    @State private var selectedJobForDetails: MediaJob? = nil
    
    public init(queueManager: QueueManager) {
        self.queueManager = queueManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("İşlem Kuyruğu")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Medya işleme görevlerinizin anlık durumu, işlem hızları ve çıktı dosyaları.")
                        .font(.system(size: 13))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                
                Spacer()
                
                if !queueManager.jobs.isEmpty {
                    HStack(spacing: 10) {
                        if queueManager.completedCount > 0 {
                            Button("Tamamlananları Temizle") {
                                queueManager.clearCompleted()
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(PatooTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(PatooTheme.bgCard)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Queue Content
            if queueManager.jobs.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(PatooTheme.bgCard)
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "tray")
                            .font(.system(size: 30))
                            .foregroundColor(PatooTheme.textTertiary)
                    }
                    
                    Text("Kuyrukta Henüz İşlem Yok")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Dönüştür, Sıkıştır veya Ses Çıkar bölümlerinden dosya ekleyerek işlem başlatabilirsiniz.")
                        .font(.system(size: 12))
                        .foregroundColor(PatooTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(queueManager.jobs) { job in
                            JobCardRow(
                                job: job,
                                onCancel: {
                                    queueManager.cancelJob(id: job.id)
                                },
                                onRetry: {
                                    queueManager.retryJob(id: job.id)
                                },
                                onRemove: {
                                    queueManager.removeJob(id: job.id)
                                },
                                onShowDetails: {
                                    selectedJobForDetails = job
                                },
                                onRevealInFinder: {
                                    revealInFinder(url: job.targetURL)
                                }
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(24)
        .background(PatooTheme.bgDark)
        .sheet(item: $selectedJobForDetails) { job in
            JobDetailSheet(job: job)
        }
    }
    
    private func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

private struct JobCardRow: View {
    let job: MediaJob
    let onCancel: () -> Void
    let onRetry: () -> Void
    let onRemove: () -> Void
    let onShowDetails: () -> Void
    let onRevealInFinder: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PatooTheme.cyan.opacity(0.12))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: job.type.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(PatooTheme.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.fileName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(job.type.title)
                        Text("•")
                        Text(job.targetURL.lastPathComponent)
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(PatooTheme.textSecondary)
                    .lineLimit(1)
                }
                
                Spacer()
                
                StatusBadge(status: job.status)
                
                // Action Buttons based on status
                HStack(spacing: 6) {
                    switch job.status {
                    case .processing:
                        Button(action: onCancel) {
                            Text("İptal")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(PatooTheme.danger)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(PatooTheme.danger.opacity(0.12))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                    case .completed:
                        Button(action: onRevealInFinder) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                    .font(.system(size: 11))
                                Text("Finder'da Göster")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(PatooTheme.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(PatooTheme.cyan.opacity(0.12))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                    case .failed:
                        Button(action: onRetry) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                                Text("Yeniden Dene")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(PatooTheme.warning)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(PatooTheme.warning.opacity(0.12))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                    case .cancelled, .pending:
                        Button(action: onRemove) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(PatooTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .padding(6)
                    }
                    
                    // Log Viewer button
                    Button(action: onShowDetails) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 12))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Günlük kaydını ve detayları incele")
                    .padding(6)
                }
            }
            
            // Progress Bar (if processing or pending)
            if case .processing(let progress, let speed, let fps, let remaining) = job.status {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [PatooTheme.cyan, PatooTheme.violet],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * CGFloat(progress), 0), height: 6)
                                .shadow(color: PatooTheme.cyanGlow, radius: 4)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack(spacing: 12) {
                        Text("\(Int((progress * 100).rounded()))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(PatooTheme.cyan)
                        
                        Text("Hız: \(speed)")
                        Text("FPS: \(fps)")
                        
                        if let rem = remaining {
                            Text(rem)
                        }
                        
                        Spacer()
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(PatooTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .patooCard(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }
}

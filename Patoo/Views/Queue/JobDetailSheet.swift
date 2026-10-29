//
//  JobDetailSheet.swift
//  Patoo
//

import SwiftUI

public struct JobDetailSheet: View {
    public let job: MediaJob
    @Environment(\.dismiss) private var dismiss
    
    public init(job: MediaJob) {
        self.job = job
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.fileName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("\(job.type.title) • \(job.createdAt.formatted(date: .abbreviated, time: .standard))")
                        .font(.system(size: 11))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                
                Spacer()
                
                StatusBadge(status: job.status)
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(PatooTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(PatooTheme.borderSubtle)
            
            // Paths Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("Kaynak:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PatooTheme.textTertiary)
                        .frame(width: 50, alignment: .leading)
                    Text(job.sourceURL.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(PatooTheme.textSecondary)
                        .textSelection(.enabled)
                }
                
                HStack(alignment: .top) {
                    Text("Hedef:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PatooTheme.textTertiary)
                        .frame(width: 50, alignment: .leading)
                    Text(job.targetURL.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(PatooTheme.cyan)
                        .textSelection(.enabled)
                }
            }
            .padding(10)
            .background(PatooTheme.bgInput)
            .cornerRadius(6)
            
            // Failure banner if failed
            if case .failed(let error, let snippet) = job.status {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hata: \(error)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(PatooTheme.danger)
                    
                    if !snippet.isEmpty {
                        Text(snippet)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(PatooTheme.textSecondary)
                    }
                }
                .padding(10)
                .background(PatooTheme.danger.opacity(0.12))
                .cornerRadius(6)
            }
            
            // Console / Raw Log Terminal
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("FFmpeg Konsol Günlüğü")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(PatooTheme.textSecondary)
                    
                    Spacer()
                    
                    Button("Kopyala") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(job.rawLog, forType: .string)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(PatooTheme.cyan)
                }
                
                ScrollView {
                    Text(job.rawLog.isEmpty ? "Günlük kaydı henüz bulunmuyor." : job.rawLog)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(PatooTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 260)
                .background(Color.black.opacity(0.6))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(PatooTheme.borderSubtle, lineWidth: 1)
                )
            }
            
            HStack {
                Spacer()
                PatooButton("Kapat", style: .secondary) {
                    dismiss()
                }
            }
        }
        .padding(20)
        .frame(width: 580, height: 500)
        .background(PatooTheme.bgCard)
    }
}

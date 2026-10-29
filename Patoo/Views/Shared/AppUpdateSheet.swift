//
//  AppUpdateSheet.swift
//  Patoo
//

import SwiftUI

public struct AppUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss
    var updateManager: AppUpdateManager
    
    public init(updateManager: AppUpdateManager = .shared) {
        self.updateManager = updateManager
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Uygulama Güncellemesi")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(PatooTheme.textPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(PatooTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            // Content according to status
            switch updateManager.status {
            case .idle, .checking:
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(PatooTheme.cyan)
                    
                    Text("GitHub üzerinden yeni sürümler denetleniyor...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(PatooTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .upToDate:
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(PatooTheme.success)
                    
                    Text("Patoo Güncel!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(PatooTheme.textPrimary)
                    
                    Text("Şu anda en son sürümü kullanıyorsunuz (v\(AppUpdateManager.currentVersion)).")
                        .font(.system(size: 12))
                        .foregroundColor(PatooTheme.textSecondary)
                    
                    Button("Kapat") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PatooTheme.cyan)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .updateAvailable(let version, let notes, let url):
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(PatooTheme.cyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yeni Bir Sürüm Yayında: \(version)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(PatooTheme.textPrimary)
                            
                            Text("Mevcut: v\(AppUpdateManager.currentVersion)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(PatooTheme.textTertiary)
                        }
                    }
                    
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(PatooTheme.textSecondary)
                        .padding(12)
                        .background(PatooTheme.bgCard)
                        .cornerRadius(6)
                    
                    HStack(spacing: 10) {
                        Spacer()
                        
                        Button("Daha Sonra") {
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(PatooTheme.textTertiary)
                        
                        Button(action: {
                            updateManager.applyUpdate(targetVersion: version, releaseURL: url)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Şimdi Güncelle")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(PatooTheme.cyan)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .updating(let progress, let message):
                VStack(spacing: 14) {
                    ProgressView(value: progress, total: 1.0)
                        .tint(PatooTheme.cyan)
                    
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PatooTheme.cyan)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .updated(let message):
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(PatooTheme.success)
                    
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PatooTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Button("Kapat") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(PatooTheme.cyan)
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .error(let err):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(PatooTheme.danger)
                    
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(PatooTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Tekrar Dene") {
                        updateManager.checkForUpdates(showFeedbackIfUpToDate: true)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PatooTheme.cyan)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
        .frame(width: 400, height: 260)
        .background(PatooTheme.bgDark)
    }
}

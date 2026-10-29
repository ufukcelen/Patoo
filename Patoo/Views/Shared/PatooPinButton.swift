//
//  PatooPinButton.swift
//  Patoo
//

import SwiftUI

public struct PatooPinButton: View {
    let section: NavigationSection
    var appState: AppState
    
    public init(section: NavigationSection, appState: AppState) {
        self.section = section
        self.appState = appState
    }
    
    public var body: some View {
        Button(action: {
            appState.togglePin(section)
        }) {
            HStack(spacing: 5) {
                Image(systemName: appState.isPinned(section) ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                
                Text(appState.isPinned(section) ? "Sabitlendi" : "Hızlı Eylemlere Sabitle")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(appState.isPinned(section) ? PatooTheme.cyan : PatooTheme.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(appState.isPinned(section) ? PatooTheme.cyan.opacity(0.12) : PatooTheme.bgCard)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(appState.isPinned(section) ? PatooTheme.cyan.opacity(0.4) : PatooTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(appState.isPinned(section) ? "Genel Bakış Hızlı Eylemlerinden Kaldır" : "Genel Bakış Hızlı Eylemlerine Ekle")
    }
}

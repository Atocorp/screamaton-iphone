//
//  SettingsButton.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Bouton de réglages réutilisable pour la grille principale
struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            .background(color)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack {
        HStack {
            SettingsButton(
                title: "ESP32",
                icon: "wifi",
                color: .green,
                action: { print("ESP32 tapped") }
            )
            
            SettingsButton(
                title: "Game",
                icon: "gamecontroller.fill",
                color: .blue,
                action: { print("Game tapped") }
            )
        }
        
        HStack {
            SettingsButton(
                title: "Soon",
                icon: "questionmark",
                color: .gray.opacity(0.3),
                action: { }
            )
            .disabled(true)
            
            SettingsButton(
                title: "Start",
                icon: "play.fill",
                color: .green,
                action: { print("Start tapped") }
            )
        }
    }
    .padding()
    .background(Color.black)
}

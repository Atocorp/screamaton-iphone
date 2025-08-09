//
//  ESP32SettingsView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

// ==========================================
// 📡 PAGE ESP32 SETTINGS
// ==========================================
struct ESP32SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var bleManager: BLEManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Paramètres ESP32")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Statut de connexion
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: bleManager.isConnected ? "wifi.circle.fill" : "wifi.slash.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(bleManager.isConnected ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Statut ESP32")
                                .font(.headline)
                            Text(bleManager.isConnected ? "✅ Connecté" : "❌ Déconnecté")
                                .foregroundColor(bleManager.isConnected ? .green : .red)
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    if bleManager.isConnected {
                        Text("Niveau reçu: \(bleManager.receivedGaugeLevel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Actions ESP32
                VStack(spacing: 12) {
                    Button(action: {
                        bleManager.startScanning()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass.circle.fill")
                            Text("Rechercher ESP32")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Text("💡 Assurez-vous que votre ESP32 est allumé et en mode pairing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    ESP32SettingsView(bleManager: BLEManager())
}

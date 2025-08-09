//
//  ImageSettingsView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

// ==========================================
// 🖼️ PAGE IMAGE SETTINGS
// ==========================================
struct ImageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Réglages Image")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Logo actuel
                VStack(spacing: 12) {
                    Text("Logo actuel")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let logo = cameraManager.logoImage {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 100)
                            .cornerRadius(10)
                            .overlay(
                                Text("Aucun logo")
                                    .foregroundColor(.secondary)
                            )
                    }
                    
                    Button(action: {
                        cameraManager.importLogoImage()
                    }) {
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("Importer un logo")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 🆕 NOUVEAU: Options pour bande blanche et logo
                VStack(spacing: 16) {
                    Text("Options de présentation")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Option pour impression
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "printer.fill")
                                .foregroundColor(.blue)
                            Text("Impression")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Toggle("Ajouter bande blanche et logo", isOn: $cameraManager.addBannerForPrint)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Option pour réseau
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.green)
                            Text("Envoi réseau")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Toggle("Ajouter bande blanche et logo", isOn: $cameraManager.addBannerForNetwork)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                
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
    ImageSettingsView(cameraManager: CameraManager())
}

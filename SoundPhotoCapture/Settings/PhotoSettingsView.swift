//
//  PhotoSettingsView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

// ==========================================
// 📷 PAGE PHOTO SETTINGS
// ==========================================
struct PhotoSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var flashModeSelection: Int
    @ObservedObject var cameraManager: CameraManager
    
    @State private var tempFlashMode: Int = 0
    @State private var tempSelectedLens: LensType = .wide
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Réglages Photo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // NOUVEAU: Sélecteur d'objectif
                VStack(spacing: 12) {
                    Text("Objectif de la caméra")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if cameraManager.availableLenses.count > 1 {
                        HStack(spacing: 10) {
                            ForEach(cameraManager.availableLenses, id: \.self) { lens in
                                Button(action: {
                                    tempSelectedLens = lens
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: lens.icon)
                                            .font(.title2)
                                            .foregroundColor(tempSelectedLens == lens ? .white : .blue)
                                        
                                        Text(lens.displayName)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(tempSelectedLens == lens ? .white : .primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(tempSelectedLens == lens ? Color.blue : Color.gray.opacity(0.2))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    } else {
                        Text("📱 Cet appareil ne dispose que d'un seul objectif")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text(lensDescription(tempSelectedLens))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Mode de flash
                VStack(spacing: 12) {
                    Text("Mode de lumière")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("Mode de lumière", selection: $tempFlashMode) {
                        Text("Aucun").tag(0)
                        Text("Flash photo").tag(1)
                        Text("Torche 1s").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(flashModeDescription(tempFlashMode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
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
                    Button("Sauvegarder") {
                        // Sauvegarder le mode flash
                        flashModeSelection = tempFlashMode
                        
                        // Sauvegarder l'objectif sélectionné
                        cameraManager.selectedLens = tempSelectedLens
                        
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            tempFlashMode = flashModeSelection
            tempSelectedLens = cameraManager.selectedLens
        }
    }
    
    func flashModeDescription(_ mode: Int) -> String {
        switch mode {
        case 0: return "Pas d'éclairage supplémentaire"
        case 1: return "Flash automatique au moment de la photo"
        case 2: return "Torche allumée pendant 1 seconde"
        default: return ""
        }
    }
    
    func lensDescription(_ lens: LensType) -> String {
        switch lens {
        case .wide:
            return "Objectif principal pour photos standard"
        case .ultraWide:
            return "Grand angle pour capturer plus de scène"
        case .telephoto:
            return "Zoom optique pour photos rapprochées"
        }
    }
}

#Preview {
    @State var flashMode = 1
    @StateObject var camera = CameraManager()
    
    return PhotoSettingsView(
        flashModeSelection: $flashMode,
        cameraManager: camera
    )
}

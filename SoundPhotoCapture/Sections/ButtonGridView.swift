//
//  ButtonGridView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Grille principale 4x4 des boutons de réglages et d'actions
struct ButtonGridView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var audioManager: AudioManager
    
    // Bindings pour les sheets de réglages
    @Binding var showESP32Settings: Bool
    @Binding var showGameSettings: Bool
    @Binding var showOutputSettings: Bool
    @Binding var showPhotoSettings: Bool
    @Binding var showImageSettings: Bool
    @Binding var showSaveSettings: Bool
    
    // Bindings pour l'affichage plein écran
    @Binding var lastCapturedImage: UIImage?
    @Binding var showLastPhotoFullScreen: Bool
    
    // Fonction pour récupérer la dernière photo
    let fetchLastPhoto: (@escaping (UIImage?) -> Void) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 4), spacing: 15) {
            
            // Rangée 1
            SettingsButton(
                title: "ESP32",
                icon: "wifi",
                color: bleManager.isConnected ? .green : .gray,
                action: { showESP32Settings = true }
            )
            
            SettingsButton(
                title: "Game",
                icon: "gamecontroller.fill",
                color: .blue,
                action: { showGameSettings = true }
            )
            
            SettingsButton(
                title: "Output",
                icon: "printer.fill",
                color: .orange,
                action: { showOutputSettings = true }
            )
            
            SettingsButton(
                title: "Photo",
                icon: "camera.fill",
                color: .purple,
                action: { showPhotoSettings = true }
            )
            
            // Rangée 2
            SettingsButton(
                title: "Image",
                icon: "photo.fill",
                color: .pink,
                action: { showImageSettings = true }
            )
            
            SettingsButton(
                title: "Save",
                icon: "square.and.arrow.down.fill",
                color: .cyan,
                action: { showSaveSettings = true }
            )
            
            SettingsButton(
                title: "Full Screen",
                icon: "viewfinder",
                color: .yellow,
                action: {
                    fetchLastPhoto { image in
                        if let img = image {
                            self.lastCapturedImage = img
                            self.showLastPhotoFullScreen = true
                        }
                    }
                }
            )
            
            SettingsButton(
                title: audioManager.isMonitoring ? "Stop" : "Start",
                icon: audioManager.isMonitoring ? "stop.fill" : "play.fill",
                color: audioManager.isMonitoring ? .red : .green,
                action: { audioManager.isMonitoring.toggle() }
            )
            
            // Rangée 3 (boutons vides pour futures fonctionnalités)
            ForEach(0..<4) { index in
                SettingsButton(
                    title: "Soon",
                    icon: "questionmark",
                    color: .gray.opacity(0.3),
                    action: { }
                )
                .disabled(true)
            }
            
            // Rangée 4 (boutons vides pour futures fonctionnalités)
            ForEach(0..<4) { index in
                SettingsButton(
                    title: "Soon",
                    icon: "questionmark",
                    color: .gray.opacity(0.3),
                    action: { }
                )
                .disabled(true)
            }
        }
        .padding()
    }
}

#Preview {
    @State var showESP32 = false
    @State var showGame = false
    @State var showOutput = false
    @State var showPhoto = false
    @State var showImage = false
    @State var showSave = false
    @State var lastImage: UIImage? = nil
    @State var showFullscreen = false
    
    return ButtonGridView(
        bleManager: BLEManager(),
        audioManager: AudioManager(),
        showESP32Settings: $showESP32,
        showGameSettings: $showGame,
        showOutputSettings: $showOutput,
        showPhotoSettings: $showPhoto,
        showImageSettings: $showImage,
        showSaveSettings: $showSave,
        lastCapturedImage: $lastImage,
        showLastPhotoFullScreen: $showFullscreen,
        fetchLastPhoto: { completion in
            completion(UIImage(systemName: "photo"))
        }
    )
    .background(Color.black)
    .preferredColorScheme(.dark)
}

//
//  PhotoSettingsView.swift
//  Screamaton iPhone
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
    @State private var tempCameraPosition: CameraPosition = .back // NOUVEAU: Position de la caméra
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Photo Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // NOUVEAU: Sélecteur de position de caméra
                VStack(spacing: 12) {
                    Text("Position camera")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 10) {
                        // Caméra arrière
                        Button(action: {
                            tempCameraPosition = .back
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .foregroundColor(tempCameraPosition == .back ? .white : .blue)
                                
                                Text("BACK")
                                    .font(.caption)
                                    .foregroundColor(tempCameraPosition == .back ? .white : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(tempCameraPosition == .back ? Color.blue : Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Caméra frontale
                        Button(action: {
                            tempCameraPosition = .front
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.rotate")
                                    .font(.title2)
                                    .foregroundColor(tempCameraPosition == .front ? .white : .blue)
                                
                                Text("FrontCam")
                                    .font(.caption)
                                    .foregroundColor(tempCameraPosition == .front ? .white : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(tempCameraPosition == .front ? Color.blue : Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text(cameraPositionDescription(tempCameraPosition))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Sélecteur d'objectif (disponible pour toutes les caméras)
                VStack(spacing: 12) {
                    Text("Camera Lens")
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
                        Text("this phone has only one lens")
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
                
                // Mode de flash (même options pour toutes les caméras)
                VStack(spacing: 12) {
                    Text("Light Mode")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("Light", selection: $tempFlashMode) {
                        Text("No").tag(0)
                        Text("Flash").tag(1)
                        Text("light 1s").tag(2)
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Sauvegarder le mode flash
                        flashModeSelection = tempFlashMode
                        
                        // Sauvegarder l'objectif sélectionné
                        cameraManager.selectedLens = tempSelectedLens
                        
                        // NOUVEAU: Sauvegarder la position de caméra
                        cameraManager.cameraPosition = tempCameraPosition
                        
                        
                        // NOUVEAU: Redémarrer la session caméra
                            if cameraManager.isSessionRunning {
                                cameraManager.stopSession()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    cameraManager.startSession()
                                }
                            }
                        
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            tempFlashMode = flashModeSelection
            tempSelectedLens = cameraManager.selectedLens
            tempCameraPosition = cameraManager.cameraPosition // NOUVEAU
        }
    }
    
    func flashModeDescription(_ mode: Int) -> String {
        switch mode {
        case 0: return "No light"
        case 1: return "Flash auto "
        case 2: return "Torch light during 1 sec"
        default: return ""
        }
    }
    
    func lensDescription(_ lens: LensType) -> String {
        switch lens {
        case .wide:
            return "main lens"
        case .ultraWide:
            return "large"
        case .telephoto:
            return "Zoom "
        }
    }
    
    func cameraPositionDescription(_ position: CameraPosition) -> String {
        switch position {
        case .back:
            return "Back Cam "
        case .front:
            return "Front Cam  -  selfies"
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

//
//  GameSettingsView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

// ==========================================
// 🎮 PAGE GAME SETTINGS
// ==========================================
struct GameSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var elasticModeSelection: Int
    @Binding var shoot: CGFloat
    
    @State private var tempElasticMode: Int = 0
    @State private var tempShoot: CGFloat = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Réglages de Jeu")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Mode de progression
                VStack(spacing: 12) {
                    Text("Mode de progression")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("Mode élastique", selection: $tempElasticMode) {
                        Text("Normal").tag(0)
                        Text("Paliers").tag(1)
                        Text("Boost").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(elasticModeDescription(tempElasticMode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Tolérance de déclenchement
                VStack(spacing: 12) {
                    Text("Tolérance de déclenchement: \(Int(tempShoot))")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Photo déclenchée à: \(59 - Int(tempShoot))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("0")
                        Slider(value: $tempShoot, in: 0...5, step: 1)
                            .accentColor(.blue)
                        Text("5")
                    }
                    .foregroundColor(.primary)
                    
                    Text("Plus la valeur est élevée, plus le déclenchement est précoce")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        elasticModeSelection = tempElasticMode
                        shoot = tempShoot
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            tempElasticMode = elasticModeSelection
            tempShoot = shoot
        }
    }
    
    func elasticModeDescription(_ mode: Int) -> String {
        switch mode {
        case 0: return "Progression constante (+0.5)"
        case 1: return "Rapide au début, lent à la fin"
        case 2: return "Boost surprise au milieu!"
        default: return ""
        }
    }
}

#Preview {
    @State var elasticMode = 0
    @State var shootValue: CGFloat = 2.0
    
    return GameSettingsView(
        elasticModeSelection: $elasticMode,
        shoot: $shootValue
    )
}

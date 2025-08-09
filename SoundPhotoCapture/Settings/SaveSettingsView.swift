//
//  SaveSettingsView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

// ==========================================
// 💾 PAGE SAVE SETTINGS
// ==========================================
struct SaveSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let onSaveAll: () -> Void
    
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Sauvegarde")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Info sur la sauvegarde
                VStack(spacing: 12) {
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                    
                    Text("Sauvegarder tous les réglages")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Cette action sauvegarde :")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Mode de progression")
                        Text("• Tolérance de déclenchement")
                        Text("• Seuil de volume")
                        Text("• Mode de flash")
                        Text("• Configuration réseau")
                        Text("• Imprimantes configurées")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(10)
                
                // Bouton de sauvegarde
                Button(action: {
                    onSaveAll()
                    showSaveSuccess = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                        Text(showSaveSuccess ? "Sauvegardé !" : "Sauvegarder maintenant")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(showSaveSuccess ? Color.green : Color.cyan)
                    .cornerRadius(10)
                    .animation(.easeInOut(duration: 0.3), value: showSaveSuccess)
                }
                .disabled(showSaveSuccess)
                
                if showSaveSuccess {
                    Text("✅ Réglages sauvegardés avec succès")
                        .font(.caption)
                        .foregroundColor(.green)
                        .animation(.easeInOut(duration: 0.3), value: showSaveSuccess)
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
                    Button("Fermer") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    SaveSettingsView(onSaveAll: { print("Sauvegarde des réglages") })
}

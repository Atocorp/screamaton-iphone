import SwiftUI
import Foundation

// ==========================================
// 🖨️ PAGE OUTPUT SETTINGS
// ==========================================
struct OutputSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var networkSendingEnabled: Bool
    @Binding var processingServerIP: String
    @Binding var processingServerPort: String
    @Binding var printers: [String: URL?]
    @Binding var selectedPrinterSlot: String
    @Binding var showPrinterPicker: Bool
    
    let onTestNetwork: () -> Void
    let onSaveNetwork: () -> Void
    
    @State private var tempOutputMode: OutputMode = .printer
    @State private var tempServerIP: String = ""
    @State private var tempServerPort: String = ""
    
    // 🆕 NOUVEAU: Enum pour les modes de sortie
    enum OutputMode {
        case printer
        case network
        case none
        
        var title: String {
            switch self {
            case .printer: return "Impression"
            case .network: return "Réseau"
            case .none: return "Aucune"
            }
        }
        
        var icon: String {
            switch self {
            case .printer: return "printer.fill"
            case .network: return "network"
            case .none: return "minus.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .printer: return .green
            case .network: return .blue
            case .none: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Réglages de Sortie")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // 🆕 MODIFIÉ: Toggle 3 modes - Impression/Réseau/Aucune
                    VStack(spacing: 12) {
                        Text("Mode de sortie")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 15) {
                            ForEach([OutputMode.printer, OutputMode.network, OutputMode.none], id: \.self) { mode in
                                Button(action: {
                                    tempOutputMode = mode
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: mode.icon)
                                            .font(.title2)
                                        Text(mode.title)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 85, height: 80)
                                    .background(tempOutputMode == mode ? mode.color : Color.gray)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // 🆕 NOUVEAU: Description du mode sélectionné
                        Text(modeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Configuration réseau
                    if tempOutputMode == .network {
                        VStack(spacing: 12) {
                            Text("Configuration réseau")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Adresse IP du Mac:")
                                TextField("Ex: 192.168.1.45", text: $tempServerIP)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numbersAndPunctuation)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Port:")
                                TextField("8080", text: $tempServerPort)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            Button(action: onTestNetwork) {
                                HStack {
                                    Image(systemName: "wifi.circle.fill")
                                    Text("Tester la connexion")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Configuration imprimantes
                    if tempOutputMode == .printer {
                        VStack(spacing: 12) {
                            Text("Imprimantes P1-P4")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 4), spacing: 15) {
                                ForEach(["P1", "P2", "P3", "P4"], id: \.self) { slot in
                                    Button(action: {
                                        selectedPrinterSlot = slot
                                        showPrinterPicker = true
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "printer.fill")
                                                .font(.title2)
                                            Text(slot)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                            Circle()
                                                .fill(printers[slot] != nil ? Color.green : Color.gray)
                                                .frame(width: 5, height: 5)
                                            
                                            if printers[slot] != nil {
                                                Text(shortPrinterSuffix(for: slot))
                                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 80)
                                        .background(printerColor(for: slot))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // 🆕 NOUVEAU: Info mode "Aucune sortie"
                    if tempOutputMode == .none {
                        VStack(spacing: 12) {
                            Text("Mode sans sortie")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                
                                Text("Photos sauvegardées uniquement")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                
                                Text("Les photos seront prises et sauvegardées dans la galerie, mais ne seront ni imprimées ni envoyées sur le réseau.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sauvegarder") {
                        // 🆕 MODIFIÉ: Sauvegarder selon le mode choisi
                        switch tempOutputMode {
                        case .printer:
                            networkSendingEnabled = false
                        case .network:
                            networkSendingEnabled = true
                            processingServerIP = tempServerIP
                            processingServerPort = tempServerPort
                        case .none:
                            networkSendingEnabled = false
                        }
                        
                        onSaveNetwork()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .sheet(isPresented: $showPrinterPicker) {
            PrinterPickerView(
                selectedSlot: selectedPrinterSlot,
                onPrinterSelected: { url in
                    printers[selectedPrinterSlot] = url
                    if let url = url {
                        UserDefaults.standard.set(url.absoluteString, forKey: "printer_\(selectedPrinterSlot)")
                    }
                }
            )
        }
        .onAppear {
            // 🆕 MODIFIÉ: Déterminer le mode actuel
            if networkSendingEnabled {
                tempOutputMode = .network
            } else if printers.values.contains(where: { $0 != nil }) {
                tempOutputMode = .printer
            } else {
                tempOutputMode = .none
            }
            
            tempServerIP = processingServerIP
            tempServerPort = processingServerPort
        }
    }
    
    // 🆕 NOUVEAU: Description du mode sélectionné
    var modeDescription: String {
        switch tempOutputMode {
        case .printer:
            return "Les photos seront imprimées sur l'imprimante sélectionnée"
        case .network:
            return "Les photos seront envoyées au serveur Processing via WiFi"
        case .none:
            return "Les photos seront uniquement sauvegardées dans la galerie"
        }
    }
    
    // MARK: - Helper Functions
    
    func printerColor(for slot: String) -> Color {
        switch slot {
        case "P1": return Color.red
        case "P2": return Color.blue
        case "P3": return Color.pink
        case "P4": return Color.orange
        default: return Color.gray
        }
    }
    
    func shortPrinterSuffix(for slot: String) -> String {
        if let url = printers[slot] ?? nil {
            let base = url.host ?? url.absoluteString
            let cleanBase = base.replacingOccurrences(of: ".local", with: "")
            return String(cleanBase.suffix(6))
        }
        return ""
    }
}

/*
import SwiftUI
import AVFoundation
import CoreBluetooth
import Photos
import CoreImage

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var bleManager = BLEManager()
    @StateObject private var cameraManager = CameraManager()
    
    @State private var threshold: CGFloat = 80
    @State private var gaugeLevel: CGFloat = 0.0
    @State private var timer: Timer?
    @State private var hasTriggeredPhoto = false
    @State private var shoot: CGFloat = 0
    @State private var flashModeSelection: Int = 0
    @State private var photoRefreshTimer: Timer?
    
    // États pour l'envoi réseau
    @State private var networkSendingEnabled = false
    @State private var processingServerIP = "192.168.1.117" // IP par défaut à modifier
    @State private var processingServerPort = "8080"
    @State private var showNetworkSettings = false
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    // 🆕 NOUVEAU: Mode de progression élastique
    @State private var elasticModeSelection: Int = 0
    
    // Ajouts pour la vue plein écran
    @State private var showLastPhotoFullScreen = false
    @State private var lastCapturedImage: UIImage? = nil
    
    // 🆕 Nouveaux états pour le flux vidéo
    @State private var showCameraFeed = false
    @State private var cameraFeedSession: AVCaptureSession?
    
    // 🆕 État pour l'écran blanc de flash
    @State private var showFlashScreen = false
    @State private var waitingForNewPhoto = false
    
    // 🆕 AJOUTER: État pour l'écran rouge de transition
    @State private var showRedTransition = false
    
    // 🎨 NOUVEAU: États pour les imprimantes P1-P4
    @State private var printers: [String: URL?] = [
        "P1": nil,
        "P2": nil,
        "P3": nil,
        "P4": nil
    ]
    @State private var currentPrinterIndex = 0
    @State private var showPrinterPicker = false
    @State private var selectedPrinterSlot = "P1"
    
    // NOUVEAUX ÉTATS À AJOUTER AU DÉBUT DE ContentView
    @State private var showESP32Settings = false
    @State private var showGameSettings = false
    @State private var showOutputSettings = false
    @State private var showPhotoSettings = false
    @State private var showImageSettings = false
    @State private var showSaveSettings = false
    
    func saveNetworkSettings() {
        UserDefaults.standard.set(processingServerIP, forKey: "processingServerIP")
        UserDefaults.standard.set(processingServerPort, forKey: "processingServerPort")
        UserDefaults.standard.set(networkSendingEnabled, forKey: "networkSendingEnabled")
        print("✅ Paramètres réseau sauvegardés: \(processingServerIP):\(processingServerPort)")
    }

    func loadNetworkSettings() {
        processingServerIP = UserDefaults.standard.string(forKey: "processingServerIP") ?? "192.168.1.117"
        processingServerPort = UserDefaults.standard.string(forKey: "processingServerPort") ?? "8080"
        networkSendingEnabled = UserDefaults.standard.bool(forKey: "networkSendingEnabled")
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    func testNetworkConnection() {
        guard let url = URL(string: "http://\(processingServerIP):\(processingServerPort)") else {
            showAlert(title: "❌ Erreur", message: "URL invalide: \(processingServerIP):\(processingServerPort)")
            return
        }
        
        print("🧪 Test connexion vers: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        request.setValue("iPhone-ScreamApp/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "❌ Échec connexion",
                                 message: "Impossible de joindre \(self.processingServerIP):\(self.processingServerPort)\n\nErreur: \(error.localizedDescription)\n\n💡 Vérifiez que:\n- Processing est lancé\n- IP correcte (pas 127.0.0.1)\n- Même réseau WiFi")
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let data = data, let responseText = String(data: data, encoding: .utf8) {
                            self.showAlert(title: "✅ Connexion réussie!",
                                         message: "Processing répond: \(responseText)")
                        } else {
                            self.showAlert(title: "✅ Connexion réussie!",
                                         message: "Serveur Processing connecté! (Code: \(httpResponse.statusCode))")
                        }
                    } else {
                        self.showAlert(title: "⚠️ Réponse inattendue",
                                     message: "Code serveur: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }


    
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 20) {
                // Titre principal
                titleSection
                
                // Volume (décibels)
                volumeDisplay
                
                // Jauge LED
                ledGaugeSection
                
                // Seuil de déclenchement
                thresholdControl
                
                // Grille de boutons 4x4
                buttonGrid
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showESP32Settings) {
            ESP32SettingsView(bleManager: bleManager)
        }
        .sheet(isPresented: $showGameSettings) {
            GameSettingsView(
                elasticModeSelection: $elasticModeSelection,
                shoot: $shoot
            )
        }
        .sheet(isPresented: $showOutputSettings) {
            OutputSettingsView(
                networkSendingEnabled: $networkSendingEnabled,
                processingServerIP: $processingServerIP,
                processingServerPort: $processingServerPort,
                printers: $printers,
                selectedPrinterSlot: $selectedPrinterSlot,
                showPrinterPicker: $showPrinterPicker,
                onTestNetwork: testNetworkConnection,
                onSaveNetwork: saveNetworkSettings
            )
        }
        .sheet(isPresented: $showPhotoSettings) {
            PhotoSettingsView(flashModeSelection: $flashModeSelection)
        }
        .sheet(isPresented: $showImageSettings) {
            ImageSettingsView(cameraManager: cameraManager)
        }
        .sheet(isPresented: $showSaveSettings) {
            SaveSettingsView(onSaveAll: saveAllSettings)
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
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            bleManager.startScanning()
            startGaugeTimer()
            cameraManager.requestPermissions()
            loadSavedPrinters()
            loadNetworkSettings()
            loadAllSettings()
        }
        .onChange(of: audioManager.volume) { newVolume in
            bleManager.sendVolumeAndGauge(volume: Int(newVolume), gauge: Int(gaugeLevel))
        }
        .onChange(of: showLastPhotoFullScreen) { isPresented in
            if isPresented {
                startPhotoRefreshTimer()
                fetchLastPhoto { image in
                    if let img = image {
                        self.lastCapturedImage = img
                    }
                }
            } else {
                stopPhotoRefreshTimer()
                stopCameraFeed()
                showFlashScreen = false
                waitingForNewPhoto = false
            }
        }
        .onChange(of: gaugeLevel) { level in
            if showLastPhotoFullScreen {
                if level > 23 && level <= 28 {
                    showRedTransition = true
                    showCameraFeed = false
                    showFlashScreen = false
                }
                else if level > 28 && level < (59 - shoot - 2) {
                    showRedTransition = false
                    if !showCameraFeed && !showFlashScreen {
                        startCameraFeed()
                    }
                }
                else if level >= (59 - shoot - 2) && !showFlashScreen && !hasTriggeredPhoto {
                    showRedTransition = false
                    showFlashScreen = true
                    showCameraFeed = false
                }
                else if level <= 23 {
                    showRedTransition = false
                    if showCameraFeed {
                        stopCameraFeed()
                    }
                    if !waitingForNewPhoto {
                        showFlashScreen = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showLastPhotoFullScreen) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 🆕 LOGIQUE D'AFFICHAGE MISE À JOUR
                if showFlashScreen {
                    // 🔥 Écran blanc de flash
                    Color.white
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.1), value: showFlashScreen)
                } else if showRedTransition {
                    // 🔴 NOUVEAU: Écran rouge de transition
                    Color.red
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.2), value: showRedTransition)
                } else if showCameraFeed {
                    // 📷 Vue du flux caméra
                    CameraFeedView(session: cameraManager.captureSession)
                        .ignoresSafeArea()
                } else if let image = lastCapturedImage {
                    // 📸 Vue de la photo
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 🖤 Écran noir par défaut
                    Color.black
                        .ignoresSafeArea()
                    Text("Aucune image")
                        .foregroundColor(.white)
                        .font(.title)
                }
                
                // 🆕 Ligne de progression (masquée pendant flash ET transition rouge)
                if !showFlashScreen && !showRedTransition {
                    VStack {
                        Spacer()
                        HStack {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: UIScreen.main.bounds.width * (gaugeLevel / 59), height: 4)
                                .animation(.linear(duration: 0.05), value: gaugeLevel)
                            Spacer()
                        }
                    }
                }
            }
            .onTapGesture {
                showLastPhotoFullScreen = false
            }
        }
    }
    
    // 🆕 NOUVEAU: Section des imprimantes P1-P4
    var printerSelectionSection: some View {
        VStack(spacing: 12) {
            Text("Imprimantes")
                .foregroundColor(.white)
                .font(.headline)
            
            HStack(spacing: 15) {
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
                            // Indicateur de statut
                            Circle()
                                .fill(printers[slot] != nil ? Color.green : Color.gray)
                                .frame(width: 5, height: 5)
                            
                            // 🆕 Identifiant court sous le bouton
                            if printers[slot] != nil {
                                Text(shortPrinterSuffix(for: slot))
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(printerColor(for: slot))
                        .cornerRadius(12)
                    }
                }
            }
            
            // 🆕 Affichage de l'imprimante courante
            if getAssignedPrinters().count > 0 {
                let currentPrinter = getCurrentPrinter()
                Text("Prochaine: \(currentPrinter.slot) (\(shortPrinterID(currentPrinter.url)))")
                    .foregroundColor(.white)
                    .font(.caption)
                    .opacity(0.8)
            } else {
                Text("Aucune imprimante assignée")
                    .foregroundColor(.white)
                    .font(.caption)
                    .opacity(0.6)
            }
        }
    }
    
    // 🎨 Couleurs pour les boutons P1-P4
    func printerColor(for slot: String) -> Color {
        switch slot {
        case "P1": return Color.red
        case "P2": return Color.blue
        case "P3": return Color.pink
        case "P4": return Color.orange
        default: return Color.gray
        }
    }
    
    // 🔄 Obtenir les imprimantes assignées
    func getAssignedPrinters() -> [(slot: String, url: URL)] {
        return printers.compactMap { key, value in
            guard let url = value else { return nil }
            return (slot: key, url: url)
        }.sorted { $0.slot < $1.slot }
    }
    
    // 🎯 Obtenir l'imprimante courante avec rotation
    func getCurrentPrinter() -> (slot: String, url: URL) {
        let assigned = getAssignedPrinters()
        if assigned.isEmpty {
            return (slot: "Aucune", url: URL(string: "")!)
        }
        return assigned[currentPrinterIndex % assigned.count]
    }
    
    // 🔄 Rotation vers la prochaine imprimante
    func rotateToNextPrinter() {
        let assigned = getAssignedPrinters()
        if !assigned.isEmpty {
            currentPrinterIndex = (currentPrinterIndex + 1) % assigned.count
            print("🔄 Rotation vers imprimante suivante: \(getCurrentPrinter().slot)")
        }
    }
    
    // 💾 Charger les imprimantes sauvegardées
    func loadSavedPrinters() {
        for slot in ["P1", "P2", "P3", "P4"] {
            if let savedURLString = UserDefaults.standard.string(forKey: "printer_\(slot)"),
               let savedURL = URL(string: savedURLString) {
                printers[slot] = savedURL
            }
        }
    }
    
    // ✅ CORRECTION: Fonctions plus sécurisées
    func startCameraFeed() {
        showCameraFeed = true
    }
    
    func stopCameraFeed() {
        showCameraFeed = false
    }
    
    func shortPrinterID(_ url: URL) -> String {
        let base = url.host ?? url.absoluteString
        return base.replacingOccurrences(of: ".local", with: "")
    }
    
    func shortPrinterSuffix(for slot: String) -> String {
        if let url = printers[slot] ?? nil {
            let base = shortPrinterID(url)
            return String(base.suffix(6))
        }
        return ""
    }
    
    // Reste de tes fonctions existantes...
    func fetchLastPhoto(completion: @escaping (UIImage?) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        if let asset = fetchResult.firstObject {
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 2000, height: 2000)
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                completion(image)
            }
        } else {
            completion(nil)
        }
    }
    
    func startPhotoRefreshTimer() {
        photoRefreshTimer?.invalidate()
        photoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            fetchLastPhoto { image in
                if let img = image {
                    self.lastCapturedImage = img
                }
            }
        }
    }

    func stopPhotoRefreshTimer() {
        photoRefreshTimer?.invalidate()
        photoRefreshTimer = nil
    }

    
    // 🆕 NOUVEAU: Sélecteur de mode élastique
    var elasticModePicker: some View {
        VStack(spacing: 8) {
            Text("Mode de progression")
                .foregroundColor(.white)
                .font(.headline)
            
            Picker("Mode élastique", selection: $elasticModeSelection) {
                Text("Normal").tag(0)
                Text("Paliers").tag(1)
                Text("Boost").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // 🆕 Description du mode sélectionné
            Text(elasticModeDescription)
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // 🆕 Description des modes
    var elasticModeDescription: String {
        switch elasticModeSelection {
        case 0:
            return "Progression constante (+0.5)"
        case 1:
            return "Rapide au début, lent à la fin"
        case 2:
            return "Boost surprise au milieu!"
        default:
            return ""
        }
    }
    
    func startGaugeTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if audioManager.volume > threshold {
                
                // 🎯 SÉLECTION DU MODE DE PROGRESSION
                let increment = calculateIncrement(mode: elasticModeSelection, currentLevel: gaugeLevel)
                gaugeLevel += increment
                
                // 🆕 Écran blanc de flash à 59-shoot-2
                if gaugeLevel >= (59 - shoot - 2) && !showFlashScreen && !hasTriggeredPhoto {
                    showFlashScreen = true
                    showCameraFeed = false // Arrêter le flux caméra
                }
                
                // 🔥 Capturer la photo au bon moment
                if gaugeLevel >= (59 - shoot) && !hasTriggeredPhoto {
                    hasTriggeredPhoto = true
                    waitingForNewPhoto = true
                    capturePhoto()
                }
                
                // 🆕 Plafonner à 59 et remettre à 0
                if gaugeLevel >= 59 {
                    gaugeLevel = 0
                    hasTriggeredPhoto = false
                    return
                }
            } else {
                gaugeLevel -= 0.25
                if gaugeLevel < 0 {
                    gaugeLevel = 0
                }
                if gaugeLevel < 50 {
                    hasTriggeredPhoto = false
                    if !waitingForNewPhoto {
                        showFlashScreen = false
                    }
                }
            }
            if bleManager.isConnected {
                bleManager.sendVolumeAndGauge(volume: Int(audioManager.volume), gauge: Int(gaugeLevel))
            }
        }
    }
    
    // 🎯 FONCTION PRINCIPALE DE CALCUL D'INCRÉMENT
    func calculateIncrement(mode: Int, currentLevel: CGFloat) -> CGFloat {
        switch mode {
        case 0:
            return 0.5  // Mode normal (original)
        case 1:
            return calculatePalierElasticIncrement(currentLevel: currentLevel)
        case 2:
            return calculateBoostElasticIncrement(currentLevel: currentLevel)
        default:
            return 0.5
        }
    }
    
    // 🏗️ MODE PALIERS: Progression par zones
    func calculatePalierElasticIncrement(currentLevel: CGFloat) -> CGFloat {
        switch currentLevel {
        case 0..<15:     return 1.5  // 🚀 Démarrage ultra rapide
        case 15..<30:    return 1  // 🏃 Rapide
        case 30..<40:    return 0.8  // 🚶 Moyen
        case 40..<48:    return 0.6// 🐌 Lent
        case 48..<55:    return 0.3  // 🐛 Très lent
        default:         return 0.2  // 🦶 Ultra lent (fin)
        }
    }
    
    // 🚀 MODE BOOST: Avec accélération surprise
    func calculateBoostElasticIncrement(currentLevel: CGFloat) -> CGFloat {
        let maxLevel: CGFloat = 59
        let progress = currentLevel / maxLevel
        
        if progress < 0.2 {
            return 2.8  // 🏃 Rapide au début
        } else if progress > 0.3 && progress < 0.5 {
            return 4.0  // 🚀 BOOST ZONE !
        } else if progress > 0.8 {
            return 0.3  // 🐌 Très lent à la fin
        } else {
            return 1.5  // 🚶 Vitesse normale
        }
    }
    
    // 📉 FONCTION DE DÉCRÉMENTATION
    func calculateDecrement(mode: Int, currentLevel: CGFloat) -> CGFloat {
        switch mode {
        case 0:
            return 0.25  // Mode normal
        case 1:
            // Paliers: décrémentation variable
            return currentLevel > 40 ? 0.4 : 0.25
        case 2:
            // Boost: décrémentation plus rapide après boost
            return currentLevel > 30 ? 0.5 : 0.25
        default:
            return 0.25
        }
    }
    
    
    func sendImageToProcessingServer(_ image: UIImage) {
        guard let url = URL(string: "http://\(processingServerIP):\(processingServerPort)"),
              let imageData = image.jpegData(compressionQuality: 0.9) else {
            print("❌ Impossible de préparer l'envoi réseau")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("iPhone-ScreamApp/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = imageData
        request.timeoutInterval = 15.0
        
        print("📡 Envoi image (\(imageData.count) bytes) vers \(processingServerIP):\(processingServerPort)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur envoi réseau: \(error.localizedDescription)")
                    // Optionnel: afficher une alerte
                    self.showAlert(title: "❌ Échec envoi", message: error.localizedDescription)
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Image envoyée avec succès au serveur Processing!")
                    } else {
                        print("⚠️ Réponse serveur: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
    
    // Fonctions de sauvegarde à ajouter
    func loadAllSettings() {
        // Charger tous les réglages sauvegardés
        elasticModeSelection = UserDefaults.standard.integer(forKey: "elasticModeSelection")
        shoot = CGFloat(UserDefaults.standard.double(forKey: "shootTolerance"))
        threshold = CGFloat(UserDefaults.standard.double(forKey: "threshold"))
        if threshold == 0 { threshold = 80 } // valeur par défaut
        flashModeSelection = UserDefaults.standard.integer(forKey: "flashModeSelection")
    }

    func saveAllSettings() {
        UserDefaults.standard.set(elasticModeSelection, forKey: "elasticModeSelection")
        UserDefaults.standard.set(Double(shoot), forKey: "shootTolerance")
        UserDefaults.standard.set(Double(threshold), forKey: "threshold")
        UserDefaults.standard.set(flashModeSelection, forKey: "flashModeSelection")
        saveNetworkSettings()
        print("✅ Tous les réglages sauvegardés")
    }

    // 🔄 CORRIGÉ: Fonction capturePhoto avec rotation d'imprimantes
    func capturePhoto() {
        let useFlash = flashModeSelection == 1
        let useTorch = flashModeSelection == 2

        // Obtenir l'imprimante courante
        let currentPrinter = getCurrentPrinter()
        
        // 🆕 Synchroniser les paramètres réseau avec CameraManager
        cameraManager.networkSendingEnabled = networkSendingEnabled
        cameraManager.processingServerIP = processingServerIP
        cameraManager.processingServerPort = processingServerPort
        
        // ✅ Capturer la photo avec le mode choisi
        cameraManager.capturePhotoAndPrint(
            useFlash: useFlash,
            useTorch: useTorch,
            printerURL: currentPrinter.url
        ) { success in
            if success {
                // Rotation vers l'imprimante suivante (seulement si en mode impression)
                if !self.networkSendingEnabled {
                    self.rotateToNextPrinter()
                }
                
                // Charger la nouvelle photo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.fetchLastPhoto { image in
                        if let img = image {
                            DispatchQueue.main.async {
                                self.lastCapturedImage = img
                                self.showFlashScreen = false
                                self.waitingForNewPhoto = false
                                print("✅ Nouvelle photo chargée et flash arrêté")
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showFlashScreen = false
                    self.waitingForNewPhoto = false
                    print("❌ Échec capture - flash arrêté")
                }
            }
        }
    }
    // Tes vues existantes restent identiques...
    var backgroundView: some View {
        Color(red: 0.2, green: 0.0, blue: 0.6)
            .ignoresSafeArea()
    }

    var titleSection: some View {
        Text("Screamaton")
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 20)
    }

    var volumeDisplay: some View {
        Text("\(Int(audioManager.volume))%")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
    }

    var ledGaugeSection: some View {
        VStack(spacing: 5) {
            Text("Jauge LED (0-58)")
                .foregroundColor(.white)
                .font(.headline)
            LEDGaugeView(gaugeLevel: Int(gaugeLevel))
            Text("Niveau: \(Int(gaugeLevel))")
                .foregroundColor(.white)
                .font(.caption)
        }
    }

    var thresholdControl: some View {
        VStack(spacing: 10) {
            Text("Seuil de déclenchement: \(Int(threshold))%")
                .foregroundColor(.white)
                .font(.headline)
            HStack {
                Text("0")
                Slider(value: $threshold, in: 0...100)
                    .accentColor(.white)
                Text("100")
            }
            .foregroundColor(.white)
            .padding(.horizontal)
        }
    }
    
    
    var buttonGrid: some View {
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
    
    
    // Composant de bouton réutilisable
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
    
  
    
    
    var fullscreenButton: some View {
        Button(action: {
            fetchLastPhoto { image in
                if let img = image {
                    self.lastCapturedImage = img
                    self.showLastPhotoFullScreen = true
                }
            }
        }) {
            Label("Afficher dernière photo", systemImage: "photo")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(20)
        }
    }

    var shootControl: some View {
        VStack(spacing: 10) {
            Text("Tolérance de déclenchement: \(Int(shoot)) → photo à \(59 - Int(shoot))")
                .foregroundColor(.white)
                .font(.headline)
            HStack {
                Text("0")
                Slider(value: $shoot, in: 0...5, step: 1)
                    .accentColor(.white)
                Text("5")
            }
            .foregroundColor(.white)
            .padding(.horizontal)
        }
    }

    var statusSection: some View {
        HStack {
            Image(systemName: "wifi")
                .foregroundColor(bleManager.isConnected ? .green : .gray)
            Text(bleManager.isConnected ? "ESP32 prêt" : "Recherche ESP32...")
                .foregroundColor(bleManager.isConnected ? .green : .white)
        }
        .font(.headline)
    }

    var flashModePicker: some View {
        Picker("Mode de lumière", selection: $flashModeSelection) {
            Text("Aucun").tag(0)
            Text("Flash photo").tag(1)
            Text("Torche 1s").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }

    var controlButton: some View {
        Button(action: {
            audioManager.isMonitoring.toggle()
        }) {
            Label(
                audioManager.isMonitoring ? "Arrêter" : "Démarrer",
                systemImage: audioManager.isMonitoring ? "stop.fill" : "play.fill"
            )
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background(audioManager.isMonitoring ? Color.red : Color.green)
            .cornerRadius(25)
        }
    }

    var outputModeSection: some View {
        VStack(spacing: 12) {
            Text("Mode de sortie")
                .foregroundColor(.white)
                .font(.headline)
            
            // Toggle principal Impression/Réseau
            HStack(spacing: 20) {
                Button(action: {
                    networkSendingEnabled = false
                    cameraManager.isPrintingEnabled = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "printer.fill")
                            .font(.title2)
                        Text("Impression")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 60)
                    .background(!networkSendingEnabled ? Color.green : Color.gray)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    networkSendingEnabled = true
                    cameraManager.isPrintingEnabled = false
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.title2)
                        Text("Réseau")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 60)
                    .background(networkSendingEnabled ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                
                // Bouton paramètres réseau
                if networkSendingEnabled {
                    Button(action: {
                        showNetworkSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 60)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Indicateur de statut
            Text(networkSendingEnabled ?
                 "📡 Envoi vers \(processingServerIP):\(processingServerPort)" :
                 "🖨️ Impression activée")
                .foregroundColor(.white)
                .font(.caption)
                .opacity(0.8)
        }
    }

    // 🆕 AJOUTER cette nouvelle vue pour les paramètres réseau:

    var networkSettingsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Paramètres réseau")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("💡 Pour trouver l'IP de votre Ordi:")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Dans Terminal tapez: ifconfig | grep \"inet \" | grep -v 127.0.0.1")
                        .font(.caption)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adresse IP du Mac:")
                        .font(.headline)
                    HStack {
                        TextField("Ex: 192.168.1.45", text: $processingServerIP)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numbersAndPunctuation)
                        
                        Button("Auto") {
                            // Proposer des IPs communes
                            processingServerIP = "192.168.1."
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Port:")
                        .font(.headline)
                    TextField("8080", text: $processingServerPort)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                // Test de connexion avec icône
                Button(action: {
                    testNetworkConnection()
                }) {
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
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        showNetworkSettings = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sauvegarder") {
                        saveNetworkSettings()
                        showNetworkSettings = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }


    var importLogoButton: some View {
        Button(action: {
            cameraManager.importLogoImage()
        }) {
            Label("Importer un logo", systemImage: "photo")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 8)
                .background(Color.purple)
                .cornerRadius(20)
        }
    }
}


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
                
                // Futures options ESP32
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔮 Futures options ESP32:")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("• Configuration WiFi\n• Calibration des LEDs\n• Mode debug\n• Mise à jour firmware")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
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
                
                // Futures options de jeu
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔮 Futures options de jeu:")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("• Difficulté adaptative\n• Modes de jeu spéciaux\n• Système de score\n• Défis quotidiens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
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
    
    @State private var tempNetworkEnabled: Bool = false
    @State private var tempServerIP: String = ""
    @State private var tempServerPort: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Réglages de Sortie")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Toggle principal Impression/Réseau
                    VStack(spacing: 12) {
                        Text("Mode de sortie")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                tempNetworkEnabled = false
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "printer.fill")
                                        .font(.title2)
                                    Text("Impression")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 80)
                                .background(!tempNetworkEnabled ? Color.green : Color.gray)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                tempNetworkEnabled = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "network")
                                        .font(.title2)
                                    Text("Réseau")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 80)
                                .background(tempNetworkEnabled ? Color.blue : Color.gray)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Configuration réseau
                    if tempNetworkEnabled {
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
                    if !tempNetworkEnabled {
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
                        networkSendingEnabled = tempNetworkEnabled
                        processingServerIP = tempServerIP
                        processingServerPort = tempServerPort
                        onSaveNetwork()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            tempNetworkEnabled = networkSendingEnabled
            tempServerIP = processingServerIP
            tempServerPort = processingServerPort
        }
    }
    
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

// ==========================================
// 📷 PAGE PHOTO SETTINGS
// ==========================================
struct PhotoSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var flashModeSelection: Int
    
    @State private var tempFlashMode: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Réglages Photo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
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
                
                // Futures options photo
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔮 Futures options photo:")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    Text("• Qualité d'image\n• Format de sortie\n• Retardateur\n• Mode rafale\n• Effets en temps réel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
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
                        flashModeSelection = tempFlashMode
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            tempFlashMode = flashModeSelection
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
}

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
                
                // Futures options image
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔮 Futures options image:")
                        .font(.headline)
                        .foregroundColor(.pink)
                    
                    Text("• Filtres photo\n• Cadres personnalisés\n• Watermarks\n• Réglages couleur\n• Compression")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.pink.opacity(0.1))
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
// 🆕 NOUVEAU: Vue pour le sélecteur d'imprimante
struct PrinterPickerView: UIViewControllerRepresentable {
    let selectedSlot: String
    let onPrinterSelected: (URL?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let picker = UIPrinterPickerController(initiallySelectedPrinter: nil)
        picker.present(animated: true) { controller, userDidSelect, error in
            if userDidSelect, let selectedPrinter = controller.selectedPrinter {
                onPrinterSelected(selectedPrinter.url)
                print("✅ Imprimante \(selectedSlot) : \(selectedPrinter.url)")
            } else {
                onPrinterSelected(nil)
                print("❌ Aucune imprimante sélectionnée pour \(selectedSlot)")
            }
            dismiss()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Pas besoin de mise à jour
    }
}

// 🆕 Nouvelle vue pour afficher le flux caméra
struct CameraFeedView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        guard let session = session else { return view }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        
        // Stocker la référence pour pouvoir mettre à jour le frame
        view.tag = 999 // identifiant pour retrouver la layer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Mettre à jour le frame de la preview layer si nécessaire
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

// Tes autres structs restent identiques...
struct LEDGaugeView: View {
    let gaugeLevel: Int
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<59) { index in
                    Rectangle()
                        .fill(index < gaugeLevel ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: (geometry.size.width - 58 * 2) / 59, height: 30)
                }
            }
        }
        .frame(height: 30)
        .padding(.horizontal)
    }
}

// Classes AudioManager et BLEManager restent identiques
class AudioManager: ObservableObject {
    @Published var volume: CGFloat = 0
    @Published var isMonitoring = true
    
    private var audioEngine = AVAudioEngine()
    private var timer: Timer?
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self, self.isMonitoring else { return }
                
                let channelData = buffer.floatChannelData?[0]
                let channelDataCount = Int(buffer.frameLength)
                
                var sum: Float = 0
                for i in 0..<channelDataCount {
                    sum += pow(channelData![i], 2)
                }
                
                let rms = sqrt(sum / Float(channelDataCount))
                let avgPower = 20 * log10(rms)
                let normalizedPower = (avgPower + 80) / 80
                
                DispatchQueue.main.async {
                    self.volume = CGFloat(max(0, min(1, normalizedPower))) * 100
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Erreur audio: \(error)")
        }
    }
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected = false
    @Published var receivedGaugeLevel: Int = 0
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    private let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    private let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [serviceUUID])
        }
    }
    
    func sendVolumeAndGauge(volume: Int, gauge: Int) {
        guard let characteristic = characteristic else { return }
        
        let data = Data([UInt8(volume), UInt8(gauge)])
        peripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        peripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        receivedGaugeLevel = 0
        startScanning()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for char in characteristics {
            if char.uuid == characteristicUUID {
                characteristic = char
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, data.count > 0 else { return }
        
        let gaugeValue = Int(data[0])
        DispatchQueue.main.async {
            self.receivedGaugeLevel = gaugeValue
        }
    }
}

class CameraManager: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var completion: ((Bool) -> Void)?
    @Published var flashEnabled: Bool = true
    @Published var isPrintingEnabled: Bool = true
    @Published var logoImage: UIImage? = nil
    @Published var currentPrintURL: URL? = nil
    @Published var printerURL: URL? {
        didSet {
            if let url = printerURL {
                UserDefaults.standard.set(url.absoluteString, forKey: "savedPrinterURL")
            }
        }
    }
    @Published var networkSendingEnabled: Bool = false
    @Published var processingServerIP: String = "192.168.1.117"
    @Published var processingServerPort: String = "8080"
    @Published var isSessionRunning: Bool = false

    
    override init() {
        super.init()
        
        if let saved = UserDefaults.standard.string(forKey: "savedPrinterURL") {
            printerURL = URL(string: saved)
        }
    }

    
    func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                self.setupCamera()
            }
        }
    }
    
    func selectPrinter() {
        let picker = UIPrinterPickerController(initiallySelectedPrinter: nil)
        picker.present(animated: true) { controller, userDidSelect, error in
            if userDidSelect, let selectedPrinter = controller.selectedPrinter {
                self.printerURL = selectedPrinter.url
                print("✅ Imprimante enregistrée : \(selectedPrinter.url)")
            } else {
                print("❌ Aucune imprimante sélectionnée.")
            }
        }
    }
    
    func fixedOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }
    
    
    func cropToSquare(_ image: UIImage) -> UIImage {
        let originalSize = image.size
        let sideLength = min(originalSize.width, originalSize.height)

        let xOffset = (originalSize.width - sideLength) / 2
        let yOffset = (originalSize.height - sideLength) / 2

        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }

        return image
    }
    
    
    func applyVignette(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let filter = CIFilter(name: "CIVignette")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.8, forKey: kCIInputIntensityKey)  // entre 0 et 2
        filter.setValue(2.0, forKey: kCIInputRadiusKey)     // entre 0 et 10

        let context = CIContext()
        if let output = filter.outputImage,
           let cgImage = context.createCGImage(output, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return image
    }
    
    func flashTorchTemporarily() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: 1.0) // 🔆 plein niveau
            device.unlockForConfiguration()

            // ⏱ Éteindre après 1 seconde
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = .off
                    device.unlockForConfiguration()
                } catch {
                    print("Erreur lors de l'extinction de la torche : \(error)")
                }
            }
        } catch {
            print("Erreur activation torche : \(error)")
        }
    }
    
    func importLogoImage() {
        DispatchQueue.main.async {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            picker.delegate = self

            // ✅ NOUVELLE MÉTHODE plus robuste
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                // Trouver le ViewController le plus haut
                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                
                topVC.present(picker, animated: true)
            }
        }
    }
    
    func addWhiteBanner(to image: UIImage) -> UIImage {
        let bannerHeight = image.size.height / 6
        let newSize = CGSize(width: image.size.width, height: image.size.height + bannerHeight)

        let renderer = UIGraphicsImageRenderer(size: newSize, format: UIGraphicsImageRendererFormat.default())

        return renderer.image { context in
            // Dessine l’image à sa taille réelle, en haut (0,0)
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Dessine un bandeau blanc en bas
            let bannerRect = CGRect(x: 0, y: image.size.height, width: image.size.width, height: bannerHeight)
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(bannerRect)

            // Logo (centré et redimensionné)
            if let logo = logoImage {
                let verticalPadding: CGFloat = bannerHeight * 0.1
                let maxHeight = bannerHeight - 2 * verticalPadding
                let ratio = logo.size.width / logo.size.height
                let targetHeight = maxHeight
                let targetWidth = targetHeight * ratio

                let logoX = (image.size.width - targetWidth) / 2
                let logoY = image.size.height + verticalPadding-20

                logo.draw(in: CGRect(x: logoX, y: logoY, width: targetWidth, height: targetHeight))
            }
        }
    }
    
    func printImage(_ image: UIImage, to printerURL: URL) {
        guard isPrintingEnabled else {
            print("🚫 Impression désactivée")
            return
        }
        
        print("🖨️ Tentative d'impression vers: \(printerURL)")
        
        let printer = UIPrinter(url: printerURL)
        
        // Vérifier d'abord si l'imprimante est disponible
        printer.contactPrinter { available in
            DispatchQueue.main.async {
                if available {
                    print("✅ Imprimante disponible, démarrage impression...")
                    
                    let printInfo = UIPrintInfo(dictionary: nil)
                    printInfo.outputType = .photo
                    printInfo.jobName = "Photo Screamaton"
                    printInfo.orientation = .portrait
                    
                    let printController = UIPrintInteractionController.shared
                    printController.printInfo = printInfo
                    printController.printingItem = image
                    
                    // Impression directe sans UI
                    printController.print(to: printer) { controller, completed, error in
                        DispatchQueue.main.async {
                            if completed {
                                print("✅ Impression réussie sur \(printerURL)")
                            } else if let error = error {
                                print("❌ Erreur d'impression: \(error.localizedDescription)")
                            } else {
                                print("⚠️ Impression annulée")
                            }
                        }
                    }
                } else {
                    print("❌ Imprimante \(printerURL) non disponible")
                }
            }
        }
    }
    
    // 5. ❌ NOUVELLE MÉTHODE À AJOUTER dans CameraManager
    func capturePhotoAndPrint(useFlash: Bool, useTorch: Bool, printerURL: URL, completion: @escaping (Bool) -> Void) {
        // Stocker l'URL de l'imprimante pour l'utiliser après capture
        self.currentPrintURL = printerURL
        self.completion = completion

        let settings = AVCapturePhotoSettings()
        settings.flashMode = useFlash ? .on : .off

        if useTorch {
            flashTorchTemporarily()
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func sendImageToProcessingServer(_ image: UIImage) {
        guard let url = URL(string: "http://\(processingServerIP):\(processingServerPort)"),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Impossible de préparer l'envoi réseau")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = imageData
        request.timeoutInterval = 10.0
        
        print("📡 Envoi image (\(imageData.count) bytes) vers \(processingServerIP):\(processingServerPort)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur envoi réseau: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Image envoyée avec succès au serveur Processing!")
                    } else {
                        print("⚠️ Réponse serveur: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }

    
    // ✅ CORRECTION: Améliorer setupCamera
        private func setupCamera() {
            // Vérifier si déjà configuré
            if !captureSession.inputs.isEmpty {
                return // Session déjà configurée
            }
            
            captureSession.beginConfiguration()
            
            // Configuration de la caméra
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                captureSession.commitConfiguration()
                return
            }
            
            // Choix d'un preset approprié
            if captureSession.canSetSessionPreset(.photo) {
                captureSession.sessionPreset = .photo
            }
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            captureSession.commitConfiguration()
            
            // ✅ Démarrer la session de manière sécurisée
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    DispatchQueue.main.async {
                        self.isSessionRunning = self.captureSession.isRunning
                    }
                }
            }
        }
    
    // ✅ AJOUTER: Méthodes pour contrôler la session
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                }
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                }
            }
        }
    }
    
    
    func capturePhoto(useFlash: Bool, useTorch: Bool, completion: @escaping (Bool) -> Void) {
        self.completion = completion

        let settings = AVCapturePhotoSettings()
        settings.flashMode = useFlash ? .on : .off

        if useTorch {
            flashTorchTemporarily()
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion?(false)
            return
        }
        
        // Traitement de l'image
        let upright = fixedOrientation(image)
        let vignetted = applyVignette(to: upright)
        let finalImage = addWhiteBanner(to: vignetted)

        // Sauvegarder dans la galerie
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: finalImage)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    // 🆕 NOUVEAU: Choisir entre impression et envoi réseau
                    if self.networkSendingEnabled {
                        // 📡 Envoi réseau vers Processing
                        self.sendImageToProcessingServer(finalImage)
                    } else if let printerURL = self.currentPrintURL {
                        // 🖨️ Impression classique
                        self.printImage(finalImage, to: printerURL)
                    }
                    self.completion?(true)
                } else {
                    print("❌ Échec sauvegarde photo: \(error?.localizedDescription ?? "Erreur inconnue")")
                    self.completion?(false)
                }
                
                // Nettoyer
                self.currentPrintURL = nil
            }
        }
    }
}

extension CameraManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            self.logoImage = selectedImage
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/

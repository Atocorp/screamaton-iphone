import SwiftUI
import AVFoundation
import CoreBluetooth
import Photos
import CoreImage

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var bleManager = BLEManager()
    @StateObject private var cameraManager = CameraManager()
    
    @State private var threshold: Double = 85.0 
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
    
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    @State private var showDoubleTapHint = false
    @State private var decibelRotation: Double = 0
    @State private var rotationTimer: Timer?
    @State private var isTransitioningCamera = false
    @State private var cameraCheckTimer: Timer?
    
    
    
    
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
    
    func startCameraMonitoring() {
        stopCameraMonitoring()
        
        cameraCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.showCameraFeed && !self.showFlashScreen {
                print("🔍 Vérification caméra - isRunning: \(self.cameraManager.isSessionRunning)")
                if !self.cameraManager.isSessionRunning {
                    print("🔧 Caméra inactive détectée - redémarrage...")
                    self.cameraManager.startSession()
                }
            }
        }
    }

    func stopCameraMonitoring() {
        cameraCheckTimer?.invalidate()
        cameraCheckTimer = nil
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
            BackgroundView()
            
            VStack(spacing: 20) {
                // Titre principal
                TitleSectionView()
                
                // Volume (décibels)
                VolumeDisplayView(audioManager: audioManager)
                
                // Jauge LED
                LEDGaugeSectionView(gaugeLevel: gaugeLevel)
                
                // Seuil de déclenchement
                ThresholdControlView(threshold: $threshold)
                
                // Grille de boutons 4x4
                ButtonGridView(
                    bleManager: bleManager,
                    audioManager: audioManager,
                    showESP32Settings: $showESP32Settings,
                    showGameSettings: $showGameSettings,
                    showOutputSettings: $showOutputSettings,
                    showPhotoSettings: $showPhotoSettings,
                    showImageSettings: $showImageSettings,
                    showSaveSettings: $showSaveSettings,
                    lastCapturedImage: $lastCapturedImage,
                    showLastPhotoFullScreen: $showLastPhotoFullScreen,
                    fetchLastPhoto: fetchLastPhoto
                )
                Spacer()
            }
            .padding()
        }
        .statusBarHidden() // ✨ Masque complètement la barre de statut
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
            PhotoSettingsView(flashModeSelection: $flashModeSelection,cameraManager: cameraManager)
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
                //stopCameraFeed()
                
                stopCameraMonitoring() // NOUVEAU
                showCameraFeed = false
                showFlashScreen = false
                waitingForNewPhoto = false
            }
        }
        .onChange(of: gaugeLevel) { level in
            if showLastPhotoFullScreen {
                print("📊 Gauge: \(level), showCameraFeed: \(showCameraFeed), showFlash: \(showFlashScreen)")
                
                // 🔴 Transition rouge (23-28) - préparer la caméra
                if level > 18 && level <= 23 {
                    showRedTransition = true
                    showCameraFeed = false
                    showFlashScreen = false
                    // 🆕 Préparer la caméra en arrière-plan pendant la transition rouge
                    if !cameraManager.isSessionRunning {
                        print("🚀 Préparation caméra pendant transition rouge")
                        cameraManager.startSession()
                    }
                }
                // 📷 Flux caméra (28 jusqu'au début du flash)
                else if level > 23 && level < (59 - shoot - 2) {
                    showRedTransition = false
                    if !showCameraFeed && !showFlashScreen {
                        print("🚀 DÉMARRAGE CAMÉRA au niveau \(level)")
                        showCameraFeed = true
                        startCameraMonitoring()
                    }
                }
                // 🔥 Flash (59-shoot-2 jusqu'à 59)
                else if level >= (59 - shoot - 2) && !showFlashScreen && !hasTriggeredPhoto {
                    showRedTransition = false
                    showFlashScreen = true
                    showCameraFeed = false
                    stopCameraMonitoring()
                }
                // 📸 Zone photo (<=23)
                else if level <= 18 {
                    showRedTransition = false
                    showCameraFeed = false
                    stopCameraMonitoring()
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
                /// rotation DB
                /*
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Calculer les décibels (0-100 → 0-120)
                        let decibels = Int((audioManager.volume / 100.0) * 120.0)
                        
                        // Calculer l'opacité (10% à 0dB, 50% à 120dB)
                        let opacity = 0.02 + (audioManager.volume / 100.0) * 0.4
                        
                        Text("\(decibels)"+" dB")
                            .font(.system(size: UIScreen.main.bounds.width / 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                            .opacity(opacity)
                            .rotationEffect(.degrees(decibelRotation))
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                 */
                
                if showDoubleTapHint {
                    VStack {
                        Spacer()
                        Text("Cliquez à nouveau pour quitter")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .transition(.opacity)
                            .animation(.easeInOut, value: showDoubleTapHint)
                        Spacer()
                    }
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
            /*
            .onAppear {
                    // NOUVEAU: Démarrer la rotation uniquement pour le fullscreen
                    rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                        withAnimation(.linear(duration: 0.02)) {
                            decibelRotation += 1.8
                            if decibelRotation >= 360 {
                                decibelRotation = 0
                            }
                        }
                    }
                }
                .onDisappear {
                    // NOUVEAU: Arrêter la rotation quand on quitte le fullscreen
                    rotationTimer?.invalidate()
                    rotationTimer = nil
                    decibelRotation = 0
                }
            */
            .onTapGesture {
                let now = Date()
                let timeDifference = now.timeIntervalSince(lastTapTime)
                
                if timeDifference < 0.5 {
                    tapCount += 1
                    if tapCount >= 2 {
                        showLastPhotoFullScreen = false
                        tapCount = 0
                        showDoubleTapHint = false
                    }
                } else {
                    tapCount = 1
                    showDoubleTapHint = true
                    // Masquer l'hint après 2 secondes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showDoubleTapHint = false
                    }
                }
                
                lastTapTime = now
            }
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
            // URL valide par défaut
            let defaultURL = URL(string: "http://localhost")!
            return (slot: "Aucune", url: defaultURL)
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
    
    /*
    func startCameraFeed() {
        guard !isTransitioningCamera else { return }
        isTransitioningCamera = true
        
        print("🎥 Démarrage caméra")
        showCameraFeed = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isTransitioningCamera = false
        }
    }

    func stopCameraFeed() {
        print("⏹️ Arrêt caméra")
        showCameraFeed = false
        isTransitioningCamera = false
    }
     */
    
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
        
        // ✅ Vérification de sécurité
           guard currentPrinter.slot != "Aucune" else {
               print("❌ Aucune imprimante configurée")
               // Capturer sans imprimer
               cameraManager.capturePhoto(useFlash: useFlash, useTorch: useTorch) { success in
                   // gérer le succès
               }
               return
           }
        
        
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
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


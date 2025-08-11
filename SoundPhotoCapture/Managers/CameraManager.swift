//
//  CameraManager.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI
import AVFoundation
import Photos
import CoreImage

// MARK: - Enum pour les types d'objectifs
enum LensType: String, CaseIterable {
    case wide = "wide"
    case ultraWide = "ultraWide"
    case telephoto = "telephoto"
    
    var displayName: String {
        switch self {
        case .wide:
            return "Standard"
        case .ultraWide:
            return "Ultra Grand Angle"
        case .telephoto:
            return "Téléobjectif"
        }
    }
    
    var icon: String {
        switch self {
        case .wide:
            return "camera.fill"
        case .ultraWide:
            return "camera.aperture"
        case .telephoto:
            return "plus.magnifyingglass"
        }
    }
    
    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .wide:
            return .builtInWideAngleCamera
        case .ultraWide:
            return .builtInUltraWideCamera
        case .telephoto:
            return .builtInTelephotoCamera
        }
    }
}
// MARK: - Enum pour position de caméra (NOUVEAU)
enum CameraPosition: String, CaseIterable {
    case back = "back"
    case front = "front"
    
    var displayName: String {
        switch self {
        case .back: return "Arrière"
        case .front: return "Frontale"
        }
    }
}

/// Gestionnaire pour la capture photo, traitement d'image et impression
class CameraManager: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var completion: ((Bool) -> Void)?
    
    // MARK: - Nouvelles propriétés pour objectifs
    @Published var availableLenses: [LensType] = []
    @Published var selectedLens: LensType = .wide {
        didSet {
            saveLensPreference()
            if captureSession.isRunning {
                switchLens(to: selectedLens)
            }
        }
    }
    @Published var cameraPosition: CameraPosition = .back {
        didSet {
            saveCameraPosition()
            // NOUVEAU: Redémarrer la session si elle tourne
            if captureSession.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.stopRunning()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.setupCamera()
                        self.startSession()
                    }
                }
            }
        }
    }
    private var currentVideoInput: AVCaptureDeviceInput?
    
    // MARK: - Propriétés existantes
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
    
    
    // 🆕 NOUVEAU: Options pour bande blanche et logo
    @Published var addBannerForPrint: Bool = true {
        didSet {
            UserDefaults.standard.set(addBannerForPrint, forKey: "addBannerForPrint")
        }
    }
    @Published var addBannerForNetwork: Bool = true {
        didSet {
            UserDefaults.standard.set(addBannerForNetwork, forKey: "addBannerForNetwork")
        }
    }
    
    @Published var outputMode: String = "printer" // "printer", "network", "none"


    override init() {
        super.init()
        
        if let saved = UserDefaults.standard.string(forKey: "savedPrinterURL") {
            printerURL = URL(string: saved)
        }
        
        // NOUVEAU: Charger préférences objectif et détecter disponibilité
        loadLensPreference()
        detectAvailableLenses()
        loadCameraPosition()
        
        // 🆕 NOUVEAU: Charger les préférences de bande blanche
        loadBannerPreferences()
    }
    
    private func saveCameraPosition() {
        UserDefaults.standard.set(cameraPosition.rawValue, forKey: "selectedCameraPosition")
    }

    private func loadCameraPosition() {
        if let savedPosition = UserDefaults.standard.string(forKey: "selectedCameraPosition"),
           let position = CameraPosition(rawValue: savedPosition) {
            cameraPosition = position
        }
    }
    
    // 🆕 NOUVEAU: Charger les préférences de bande blanche
    private func loadBannerPreferences() {
        addBannerForPrint = UserDefaults.standard.object(forKey: "addBannerForPrint") as? Bool ?? true
        addBannerForNetwork = UserDefaults.standard.object(forKey: "addBannerForNetwork") as? Bool ?? true
    }
    
    // MARK: - Nouvelles méthodes pour objectifs
    
    /// Détecte les objectifs disponibles sur l'appareil
    private func detectAvailableLenses() {
        var lenses: [LensType] = []
        
        // ✅ Utiliser la position configurée
          let position: AVCaptureDevice.Position = cameraPosition == .back ? .back : .front
          
        
        for lensType in LensType.allCases {
                if AVCaptureDevice.default(lensType.deviceType, for: .video, position: position) != nil {
                    lenses.append(lensType)
                }
            }
        
        DispatchQueue.main.async {
            self.availableLenses = lenses
            
            // Si l'objectif sélectionné n'est pas disponible, prendre Wide par défaut
            if !lenses.contains(self.selectedLens) && lenses.contains(.wide) {
                self.selectedLens = .wide
            }
        }
    }
    
    /// Change l'objectif de la caméra
    private func switchLens(to lensType: LensType) {
        
        // ✅ Utiliser la position de caméra configurée
           let devicePosition: AVCaptureDevice.Position = cameraPosition == .back ? .back : .front
           
        
        
        guard let device = AVCaptureDevice.default(lensType.deviceType, for: .video, position: devicePosition) else {
               print("❌ Objectif \(lensType.displayName) non disponible pour caméra \(cameraPosition.displayName)")
               return
           }
        
        captureSession.beginConfiguration()
        
        // Retirer l'entrée vidéo actuelle
        if let currentInput = currentVideoInput {
            captureSession.removeInput(currentInput)
        }
        
        // Ajouter la nouvelle entrée vidéo
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                currentVideoInput = newInput
                print("✅ Objectif changé vers: \(lensType.displayName)")
            }
        } catch {
            print("❌ Erreur lors du changement d'objectif: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
    
    /// Sauvegarde la préférence d'objectif
    private func saveLensPreference() {
        UserDefaults.standard.set(selectedLens.rawValue, forKey: "selectedLens")
    }
    
    /// Charge la préférence d'objectif
    private func loadLensPreference() {
        if let savedLens = UserDefaults.standard.string(forKey: "selectedLens"),
           let lensType = LensType(rawValue: savedLens) {
            selectedLens = lensType
        }
    }

    // MARK: - Méthodes existantes (inchangées)
    
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
               let rootViewController = window.rootViewController {
                
                // Trouver le ViewController le plus haut
                var topVC = rootViewController
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                
                topVC.present(picker, animated: true)
            }
        }
    }
    
    // 🆕 NOUVELLE MÉTHODE: Préparer image pour impression avec bande blanche et logo
    func prepareImageForPrint(_ image: UIImage) -> UIImage {
        return addWhiteBanner(to: image)
    }
    
    func addWhiteBanner(to image: UIImage) -> UIImage {
        let bannerHeight = image.size.height / 6
        let newSize = CGSize(width: image.size.width, height: image.size.height + bannerHeight)

        let renderer = UIGraphicsImageRenderer(size: newSize, format: UIGraphicsImageRendererFormat.default())

        return renderer.image { context in
            // Dessine l'image à sa taille réelle, en haut (0,0)
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
        
        // 🆕 MODIFIÉ: Utiliser l'image avec ou sans bande selon le réglage
        let imageForPrint = addBannerForPrint ? prepareImageForPrint(image) : image
        
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
                    printController.printingItem = imageForPrint // 🆕 Image avec ou sans bande
                    
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

    // MARK: - Setup caméra (MODIFIÉ pour supporter objectifs)
    private func setupCamera() {
        // Vérifier si déjà configuré
        if !captureSession.inputs.isEmpty {
            return // Session déjà configurée
        }
        
        captureSession.beginConfiguration()
        
        // MODIFIÉ: Configuration avec l'objectif sélectionné ET position caméra
        let devicePosition: AVCaptureDevice.Position = self.cameraPosition == .back ? .back : .front
        print("🎯 Configuration caméra: \(self.cameraPosition) -> position: \(devicePosition)")

        guard let camera = AVCaptureDevice.default(selectedLens.deviceType, for: .video, position: devicePosition),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            // Fallback vers Wide si l'objectif sélectionné n'est pas disponible
            guard let fallbackCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition),
                  let fallbackInput = try? AVCaptureDeviceInput(device: fallbackCamera) else {
                captureSession.commitConfiguration()
                return
            }
            
            if captureSession.canAddInput(fallbackInput) {
                captureSession.addInput(fallbackInput)
                currentVideoInput = fallbackInput
            }
            
            captureSession.commitConfiguration()
            return
        }
        
        // Choix d'un preset approprié
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentVideoInput = input // NOUVEAU: stocker la référence
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

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion?(false)
            return
        }
        
        // 🆕 MODIFIÉ: Traitement de base de l'image (SANS bande blanche ni logo)
        let upright = fixedOrientation(image)
        let cleanImage = applyVignette(to: upright) // Image propre pour la galerie
        
        // 🆕 IMPORTANT: Sauvegarder l'image PROPRE dans la galerie (sans bande blanche)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: cleanImage)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Image sauvegardée PROPRE dans la galerie")
                    
                    // 🆕 MODIFIÉ: Vérifier le mode de sortie
                    if self.networkSendingEnabled {
                        // 📡 Mode réseau
                        let imageForNetwork = self.addBannerForNetwork ? self.prepareImageForPrint(cleanImage) : cleanImage
                        self.sendImageToProcessingServer(imageForNetwork)
                    } else if let printerURL = self.currentPrintURL {
                        // 🖨️ Mode impression
                        self.printImage(cleanImage, to: printerURL)
                    } else {
                        // 📱 Mode "Aucune sortie" - juste sauvegarder
                        print("📱 Mode sans sortie - photo sauvegardée uniquement")
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

// MARK: - UIImagePickerControllerDelegate

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

//
//  CameraFeedView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI
import AVFoundation

// 🆕 Vue pour afficher le flux caméra avec LOGS
struct CameraFeedView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        print("🎥 CameraFeedView makeUIView appelé")
        
        guard let session = session else {
            print("❌ Session est nil dans CameraFeedView")
            return view
        }
        
        print("✅ Session existe, isRunning: \(session.isRunning)")
        print("📊 Session inputs: \(session.inputs.count)")
        print("📊 Session outputs: \(session.outputs.count)")
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        view.tag = 999
        
        print("🎬 PreviewLayer ajouté")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("🔄 CameraFeedView updateUIView appelé")
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
                print("📐 Frame mis à jour: \(uiView.bounds)")
            }
        }
    }
}

//
//  AudioManager.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI
import AVFoundation

/// Gestionnaire pour la capture et le monitoring audio
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

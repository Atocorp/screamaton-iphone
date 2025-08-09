//
//  VolumeDisplayView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Affichage du volume en pourcentage
struct VolumeDisplayView: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        Text("\(Int(audioManager.volume))%")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
    }
}

#Preview {
    VStack {
        VolumeDisplayView(audioManager: AudioManager())
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}

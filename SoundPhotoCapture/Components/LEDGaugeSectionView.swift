//
//  LEDGaugeSectionView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Section complète affichant la jauge LED avec titre et niveau
struct LEDGaugeSectionView: View {
    let gaugeLevel: Double
    
    var body: some View {
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
}

#Preview {
    VStack {
        LEDGaugeSectionView(gaugeLevel: 25)
        LEDGaugeSectionView(gaugeLevel: 45)
        LEDGaugeSectionView(gaugeLevel: 58)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

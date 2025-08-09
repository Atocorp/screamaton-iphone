//
//  ThresholdControlView`.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Contrôle du seuil de déclenchement avec slider
struct ThresholdControlView: View {
    @Binding var threshold: Double
    
    var body: some View {
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
}

#Preview {
    @State var threshold = 50.0
    
    return VStack {
        ThresholdControlView(threshold: $threshold)
        Text("Valeur actuelle: \(Int(threshold))")
            .foregroundColor(.white)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

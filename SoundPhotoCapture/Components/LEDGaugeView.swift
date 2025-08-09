//
//  LEDGaugeView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Jauge LED horizontale avec 59 segments
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

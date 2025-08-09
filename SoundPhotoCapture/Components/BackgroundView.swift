//
//  BackgroundView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Fond violet de l'application
struct BackgroundView: View {
    var body: some View {
        Color(red: 0.2, green: 0.0, blue: 0.6)
            .ignoresSafeArea()
    }
}

#Preview {
    BackgroundView()
}

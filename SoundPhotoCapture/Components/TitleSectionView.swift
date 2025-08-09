//
//  TitleSectionView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Titre principal "Screamaton"
struct TitleSectionView: View {
    var body: some View {
        Text("Screamaton")
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 20)
    }
}

#Preview {
    TitleSectionView()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

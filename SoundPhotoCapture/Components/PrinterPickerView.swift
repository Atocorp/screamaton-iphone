//
//  PrinterPickerView.swift
//  Screamaton 9
//
//  Created by antonin Fourneau on 17/06/2025.
//

import SwiftUI

/// Vue pour sélectionner une imprimante via le système iOS
struct PrinterPickerView: UIViewControllerRepresentable {
    let selectedSlot: String
    let onPrinterSelected: (URL?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let picker = UIPrinterPickerController(initiallySelectedPrinter: nil)
        picker.present(animated: true) { controller, userDidSelect, error in
            if userDidSelect, let selectedPrinter = controller.selectedPrinter {
                onPrinterSelected(selectedPrinter.url)
                print("✅ Imprimante \(selectedSlot) : \(selectedPrinter.url)")
            } else {
                onPrinterSelected(nil)
                print("❌ Aucune imprimante sélectionnée pour \(selectedSlot)")
            }
            dismiss()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Pas besoin de mise à jour
    }
}

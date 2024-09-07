//
//  ShareSheet.swift
//  Ranker
//
//  Created by Joseph Malone on 4/8/24.
//

import Foundation


import SwiftUI
import UIKit


// The ShareSheet wrapper from previous explanations
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

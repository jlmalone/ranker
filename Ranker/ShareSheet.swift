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

//
//struct ShareSheet: UIViewControllerRepresentable {
//    var activityItems: [Any]
//    var applicationActivities: [UIActivity]? = nil
//
//    func makeCoordinator() -> ShareSheetCoordinator {
//        return ShareSheetCoordinator()
//    }
//
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
//        
//        
//        
//        // If you're trying to present MFMailComposeViewController specifically
//        // let mailComposeViewController = MFMailComposeViewController()
//        // mailComposeViewController.mailComposeDelegate = context.coordinator
//        
//        
//        
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}


//import SwiftUI
//import UIKit

//struct ShareSheet: UIViewControllerRepresentable {
//    var items: [Any]
//    var applicationActivities: [UIActivity]? = nil
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        let controller = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
//        return controller
//    }
//    
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}

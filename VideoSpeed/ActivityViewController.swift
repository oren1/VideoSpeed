//
//  ActivityViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 12/05/2024.
//

import Foundation
import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {

    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let items = ["https://apps.apple.com/il/app/speed-up-video-slow-mo-spid/id6452276248",  UIImage(named: "AppIcon")!] as [Any]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        ac.modalPresentationStyle = .formSheet
        ac.completionWithItemsHandler = { activity, success, items, error in
            if success {
                print("Successfully shared!")
                    Task {
                        do {
                            try await NetworkManager.shared.createUser()
                            ac.dismiss(animated: true) {
                                alertMessage = "Your all set.\nyou have one month free pro version."
                                showAlert = true
                            }
                            
                        } catch {
                            ac.dismiss(animated: true) {
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                        }
                    }
                
                
            } else {
                print("Failed to share.")
            }
        }
        return ac
    }

    func updateUIViewController(_ pageViewController: UIActivityViewController, context: Context) {

    }

    class Coordinator: NSObject {
        
        init(_ activityController: ActivityViewController) {
            
        }

    }
}

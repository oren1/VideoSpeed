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
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let items = ["https://apps.apple.com/il/app/speed-up-video-slow-mo-spid/id6452276248",  UIImage(named: "AppIcon")!] as [Any]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        ac.modalPresentationStyle = .formSheet
        ac.excludedActivityTypes = [
            .print,
            .copyToPasteboard,
            .saveToCameraRoll,
            .addToReadingList,
            .postToVimeo,
            .openInIBooks,
            .markupAsPDF,
        ]
        if #available(iOS 15.4, *) {
            ac.excludedActivityTypes?.append(contentsOf: [.sharePlay])
        }
        if #available(iOS 16, *) {
            ac.excludedActivityTypes?.append(contentsOf: [
                .collaborationInviteWithLink,
                .collaborationCopyLink
            ])
        }
        if #available(iOS 16.4, *) {
            ac.excludedActivityTypes?.append(contentsOf: [.addToHomeScreen])
        }
        
        ac.completionWithItemsHandler = { activity, success, items, error in
            if success && validActivity(activity: activity) {
                print("Success completionWithItemsHandler")

                print("Successfully shared!")
                ac.dismiss(animated: true) {
                    Task {
                        do {
                            isLoading = true
                            try await NetworkManager.shared.createUser()
                            alertMessage = "Your all set.\nyou have one month free pro version."
                            showAlert = true
                            isLoading = false
                            
                        } catch ServiceError.errorWithMessage(let message) {
                            alertMessage = message
                            showAlert = true
                            isLoading = false
                        } catch {
                            alertMessage = "unexpected error occur"
                            showAlert = true
                            isLoading = false
                            
                        }
                    }

                }
            } 
            else {
                ac.dismiss(animated: true) {}
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
    
    func validActivity(activity: UIActivity.ActivityType?) -> Bool {
        guard let activity = activity else { return false }
        let activities = [
            "com.apple.DocumentManagerUICore.SaveToFiles",
            "com.apple.sharing.quick-note",
            "com.buffer.buffer.BufferIdeaComposerExtension"
        ]
        
        if activities.contains(activity.rawValue) {
            return false
        }
        
        return true
    }
    
}

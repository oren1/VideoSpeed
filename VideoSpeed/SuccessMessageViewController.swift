//
//  SuccessMessageViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 01/08/2023.
//

import UIKit
import SwiftUI

class SuccessMessageViewController: UIViewController {

    private var ratingPromptHostingController: UIHostingController<RatingPromptView>?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showRatingPromptIfNeeded()
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    

    // MARK: - Rating Prompt Flow
    
    private func showRatingPromptIfNeeded() {
        guard AppStoreReviewManager.ratingPromptLocationVariant() == "success_screen",
              AppStoreReviewManager.shouldShowRatingPrompt(),
              ratingPromptHostingController == nil else { return }
        
        let promptView = RatingPromptView(
            onPositive: { [weak self] in
                self?.handleRatingPositiveTap()
            },
            onNegative: { [weak self] in
                self?.handleRatingNegativeTap()
            }
        )
        
        let hostingController = UIHostingController(rootView: promptView)
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.preferredCornerRadius = 20
            sheet.prefersGrabberVisible = false
        }
        
        hostingController.modalPresentationStyle = .pageSheet
        ratingPromptHostingController = hostingController
        present(hostingController, animated: true)
        
        AnalyticsManager.ratingGateShownAfterExport()
    }
    
    private func hideRatingPromptView() {
        ratingPromptHostingController?.dismiss(animated: true) { [weak self] in
            self?.ratingPromptHostingController = nil
        }
    }
    
    private func handleRatingPositiveTap() {
        AppStoreReviewManager.markRatingPromptShownForCurrentVersion()
        hideRatingPromptView()
        AnalyticsManager.ratingGatePositiveTap()
        AppStoreReviewManager.requestReviewIfAppropriate()
    }
    
    private func handleRatingNegativeTap() {
        AppStoreReviewManager.markRatingPromptShownForCurrentVersion()
        hideRatingPromptView()
        AnalyticsManager.ratingGateNegativeTap()
        // Optional: could present a feedback flow here in the future.
    }
}

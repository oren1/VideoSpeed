//
//  AppStoreReviewManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 24/07/2023.
//

import Foundation
import StoreKit
import FirebaseRemoteConfig
import UIKit

enum AppStoreReviewManager {

    /// A/B test: where to show the 2-step rating prompt. "success_screen" = after export on SuccessMessageViewController; "main_after_export" = on MainViewController when returning after 3+ exports.
    static func ratingPromptLocationVariant() -> String {
        RemoteConfig.remoteConfig().configValue(forKey: "ratingPromptLocation").stringValue ?? "main_after_export"
    }
    
    static let minimumReviewWorthyActionCount = RemoteConfig.remoteConfig().configValue(forKey: "minimumReviewWorthyActionCount").numberValue.intValue
    
    // MARK: - Export Count
    
    static func incrementSuccessfulExportCount() {
        let defaults = UserDefaults.standard
        let currentCount = defaults.integer(forKey: Consts.successfulExportCount)
        defaults.set(currentCount + 1, forKey: Consts.successfulExportCount)
    }
    
    static func successfulExportCount() -> Int {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: Consts.successfulExportCount)
    }
    
    // MARK: - Rating Prompt Gate (shared for A/B test)
    
    /// Returns true when we should show the 2-step rating gate (export count >= 3, not yet shown this app version).
    static func shouldShowRatingPrompt() -> Bool {
        let exportCount = successfulExportCount()
        guard exportCount >= 3 else { return false }
        guard let currentVersion = UIApplication.appVersion else { return false }
        let defaults = UserDefaults.standard
        if let lastVersion = defaults.string(forKey: Consts.exportRatingPromptLastAppVersion),
           lastVersion == currentVersion {
            return false
        }
        return true
    }
    
    static func markRatingPromptShownForCurrentVersion() {
        guard let currentVersion = UIApplication.appVersion else { return }
        UserDefaults.standard.set(currentVersion, forKey: Consts.exportRatingPromptLastAppVersion)
    }

    // MARK: - Review Request

    static func requestReviewIfAppropriate() {
        let defaults = UserDefaults.standard

        // increasing the count by 1
        var actionCount = defaults.integer(forKey: Consts.reviewWorthyActionCount)
        actionCount += 1
        defaults.set(actionCount, forKey: Consts.reviewWorthyActionCount)

        print("worthy review count: \(actionCount)")
        // checking if the current count is bigger then the minimum review worthy count
        guard actionCount >= minimumReviewWorthyActionCount else {
          return
        }

        
        let lastVersion = defaults.string(forKey: Consts.lastReviewRequestAppVersion)
        // making sure that the review request wasn't already prompted in the current version
        guard let currentVersion = UIApplication.appVersion,
              lastVersion == nil || lastVersion != currentVersion else { return }
              

        // prompt the review request
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
        else {
            SKStoreReviewController.requestReview()
        }
        
        AnalyticsManager.ratingSystemPromptRequested()

        // reset the worthy count to zero and last app version to the current version
        defaults.set(0, forKey: Consts.reviewWorthyActionCount)
        defaults.set(currentVersion, forKey: Consts.lastReviewRequestAppVersion)

     }
  
}

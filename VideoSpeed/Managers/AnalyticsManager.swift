//
//  AnalyticsManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/01/2024.
//

import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    static func purchaseEvent() {
        let eventName = "purchase_event"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func giftButtonTappedEvent() {
        let eventName = "gift_button_pressed"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func benefitViewApearEvent() {
        let eventName = "benefit_view_apeared"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func shareButtonTappedEvent() {
        let eventName = "share_button_tapped"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func laterButtonTappedEvent() {
        let eventName = "later_button_tapped"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func successfullInviteEvent() {
        let eventName = "successfull_invite"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func failedInviteEvent() {
        let eventName = "failed_invite"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func exportButtonTapped() {
        let eventName = "export_button_tapped"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func userAuthorizedPhotoLibraryPermission() {
        let eventName = "user_authorized_photo_library_usage"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func userDeniedPhotoLibraryPermission() {
        let eventName = "user_denied_photo_library_usage"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func userLimitedPhotoLibraryPermission() {
        let eventName = "user_limited_photo_library_usage"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func userNotDeterminedPhotoLibraryPermission() {
        let eventName = "user_not_determined_photo_library_usage"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func speedUsedOnExportEvent() {
        let eventName = "speed_used_on_export"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func fpsUsedOnExportEvent() {
        let eventName = "fps_used_on_export"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func soundUsedOnExportEvent() {
        let eventName = "sound_used_on_export"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func fileTypeUsedOnExportEvent() {
        let eventName = "fileType_used_on_export"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func cropUsedOnExportEvent() {
        let eventName = "crop_used_on_export"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func trimUsedOnExportEvent() {
        let eventName = "trim_used_on_export"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func couldntGetProductsEvent() {
        let eventName = "couldnt_get_products"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func getProAndSaveVideoTapped() {
        let eventName = "get_pro_and_save_video_tapped"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func disabledNotificationsOnPermissionRequest() {
        if !UserDataManager.main.sentNotificationPermissionAnalyticStatus {
            print("disabledNotificationsOnPermissionRequest")
            let eventName = "disabled_notifications_on_request"
            Analytics.logEvent(eventName, parameters: [:])
            UserDataManager.main.sentNotificationPermissionAnalyticStatus = true
        }
    }
    
    static func enabledNotificationsOnRequest() {
        if !UserDataManager.main.sentNotificationPermissionAnalyticStatus {
            print("enabledNotificationsOnRequest")
            let eventName = "enabled_notifications_on_request"
            Analytics.logEvent(eventName, parameters: [:])
            UserDataManager.main.sentNotificationPermissionAnalyticStatus = true
        }
    }
    
    static func ratingGateShownAfterExport() {
        let eventName = "rating_gate_shown_after_export"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func ratingGatePositiveTap() {
        let eventName = "rating_gate_positive_tap"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func ratingGateNegativeTap() {
        let eventName = "rating_gate_negative_tap"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
    static func ratingSystemPromptRequested() {
        let eventName = "rating_system_prompt_requested"
        Analytics.logEvent(eventName, parameters: [:])
    }
    
}


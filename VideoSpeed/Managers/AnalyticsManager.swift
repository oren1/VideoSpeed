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
}


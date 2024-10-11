//
//  NotificationsManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 05/09/2024.
//

import Foundation

class NotificationsManager {
    
    static let resetSelectionsNotification = Notification.Name("Reset Selections")
    
    static func resetSelections() {
        NotificationCenter.default.post(name: resetSelectionsNotification, object: nil)
    }
}

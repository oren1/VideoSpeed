//
//  PublishersManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 04/09/2024.
//

import Foundation

class PublishersManager {
    
    static let main = PublishersManager()

    let resetSelectionsPublisher: NotificationCenter.Publisher
    
    init() {
        resetSelectionsPublisher = NotificationCenter.default.publisher(for: NotificationsManager.resetSelectionsNotification, object: nil)
    }

    
}

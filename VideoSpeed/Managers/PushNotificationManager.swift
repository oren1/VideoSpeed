//
//  PushNotificationManager.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 01/02/2026.
//

import Foundation
import FirebaseMessaging


class PushNotificationManager: NSObject, MessagingDelegate {
   
    static let main = PushNotificationManager()
   
    @MainActor
    func registerForPushNotificationsAsync() async {
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            

            print("Permission granted: \(granted)")
            
            guard granted else {
                AnalyticsManager.disabledNotificationsOnPermissionRequest()
                return
            }
            
            AnalyticsManager.enabledNotificationsOnRequest()
            // Must be called on main thread
            UIApplication.shared.registerForRemoteNotifications()
            
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else {
                    AnalyticsManager.disabledNotificationsOnPermissionRequest()
                    return
                }
                
                AnalyticsManager.enabledNotificationsOnRequest()
                self?.registerForRemoteNotificationIfAuthorized()
            }
        
    }
    
    func registerForRemoteNotificationIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    
}

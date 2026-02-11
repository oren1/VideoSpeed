//
//  AppDelegate.swift
//  VideoSpeed
//
//  Created by oren shalev on 13/07/2023.
//

import UIKit
import FirebaseCore
import GoogleMobileAds
import FirebaseInstallations
import FirebaseRemoteConfig
import RevenueCat
import AppTrackingTransparency
import FirebaseCrashlytics
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
    
        FirebaseApp.configure()
        
        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        Installations.installations().authTokenForcingRefresh(true, completion: { (result, error) in
          if let error = error {
            print("Error fetching token: \(error)")
            return
          }
          guard let result = result else { return }
          print("Installation auth token: \(result.authToken)")
        })
        
        
        
        RemoteConfig.remoteConfig().setDefaults(fromPlist: "remote_config_defaults")
        InterstitialAd.manager.loadInterstitialAd()

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_TMmatMjmVJesESBWZFPzLFOZpfk", appUserID: nil)
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
//        if ATTrackingManager.trackingAuthorizationStatus != .notDetermined {
//             // The user has previously seen a tracking request, so enable automatic collection
//             // before configuring in order to to collect whichever token is available
//             Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
//        }
        
        if UserDataManager.main.installationTime == nil {
            UserDataManager.main.installationTime = Date().timeIntervalSince1970
        }
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Check the URL and handle accordingly
        if url.scheme == "spidApp" {
            // Handle the URL
            print("open url: \(url)")
            return true
        }
        return false
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
        UIApplication.shared.applicationIconBadgeNumber = 0

        // If the user didn't approve notification in the first time then he will not have a 'token'.
        // if he dont have a token then always check if he changed he's settings to allow it.
        // and when he allows it request a token from apple and sent it to the Server.
        PushNotificationManager.main.registerForRemoteNotificationIfAuthorized()
        
    }
   
    
    // MARK: - MessagingDelegate
        func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
          print("Firebase registration token: \(String(describing: fcmToken))")
          // TODO: If necessary send token to application server.
          // Note: This callback is fired at each app startup and whenever a new token is generated.
        }
    
}


    
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
      -> UNNotificationPresentationOptions {
     
      let userInfo = notification.request.content.userInfo
      
      print("userInfo foreground: \(userInfo)")

      return [.list, .banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        
           let userInfo = response.notification.request.content.userInfo
           if let giftDays = userInfo["giftDays"] as? String,
               let giftDaysInt = Int(giftDays){
               
                // create a Date object with X days in the future
               let giftDueDate = Date.dateInFuture(days: giftDaysInt)
               // save it on UserDefaults
               UserDataManager.main.setGiftDueDate(giftDueDate: giftDueDate)
              
              
                DispatchQueue.main.async {
                    UIApplication.shared
                        .topViewController()?
                        .showGiftPopup(daysFree: giftDaysInt)
                }
            
        }

        print("userInfo: \(userInfo)")
    }
}


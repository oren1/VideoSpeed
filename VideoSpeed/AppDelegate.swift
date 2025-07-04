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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


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
    
}


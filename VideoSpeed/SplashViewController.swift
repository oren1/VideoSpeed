//
//  SplashViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import UIKit
import GoogleMobileAds
import FirebaseCore
import FirebaseRemoteConfig
import StoreKit

class SplashViewController: UIViewController, GADFullScreenContentDelegate {

    var appOpenAd: GADAppOpenAd?
    var adDidDismis = false
    var requestsDidFinish = false
    var error: Error?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let minimumAppOpensToShowAd = RemoteConfig.remoteConfig().configValue(forKey: "minimumAppOpensToShowAd").numberValue.intValue

        print("minimumAppOpensToShowAd \(minimumAppOpensToShowAd)")
        
        Task {
            let businessModelRawValue = RemoteConfig.remoteConfig().configValue(forKey: "business_model").stringValue!
            let businessModel = BusinessModel(rawValue: businessModelRawValue)
            if businessModel == .subscription {
               try? await refreshPurchasedProducts()
            }
        }
        
        let downloadGroup = DispatchGroup()
        
        downloadGroup.enter()
        SpidProducts.store.requestProducts { success, products in
            if let products = products, success {
                UserDataManager.main.products = products
                downloadGroup.leave()
            }
            /* In case of error it means that the products were not fetched and i dont want to enter the app
               let it be stuck and the user to reload the app
             */
        }
        
        
        downloadGroup.enter()
        getRemoteConfig {
            downloadGroup.leave()
        }
        
        downloadGroup.enter()
        loadAppOpenAdIfAppropriate(viewVontroller: self) {
            downloadGroup.leave()
        }
        
        
        
        downloadGroup.notify(queue: DispatchQueue.main) { [weak self] in
             if let appOpenAd = self?.appOpenAd,
                let rootViewController = self?.view.window?.rootViewController {
                 appOpenAd.present(fromRootViewController: rootViewController)
                 return
             }
             else {
                self?.pushMainViewController()
             }
        }
    }
    
    func refreshPurchasedProducts() async throws {
        // Iterate through the user's purchased products.
        let products = try await Product.products(for: [
            SpidProducts.monthlySubscription,
            SpidProducts.halfYearlySubscription,
            SpidProducts.yearlySubscription
        ])

        for product in products {
            guard let verificationResult = await product.currentEntitlement else {
                // The user isn’t currently entitled to this product.
                SpidProducts.store.removeProductEntitlement(productIdentifier: product.id)
                continue
            }


            switch verificationResult {
            case .verified(let transaction):
                // Check the transaction and give the user access to purchased
                // content as appropriate.
                print("transaction \(transaction)")
            case .unverified(let transaction, let verificationError):
                print("verificationError", verificationError)
                print("verificationError transaction", verificationError)
            }
        }
    
    }
    
    func loadAppOpenAdIfAppropriate(viewVontroller: UIViewController, completion: @escaping VoidClosure) {
        
        guard SpidProducts.store.userPurchasedProVersion() == nil else {
            print("AppOpenAd: purchased pro version")
            completion()
            return
        }
        
        guard AppOpenAd.manager.amountOfAppOpens >= AppOpenAd.manager.minimumAppOpensRequiredToShowAd else {
            print("AppOpenAd: amount of ads less than minimum")
            completion()
            return
        }
        
        var unitId = "ca-app-pub-5159016515859793/8839080524"
        #if DEBUG
        unitId = "ca-app-pub-3940256099942544/5575463023"
        #endif
                
        GADAppOpenAd.load(withAdUnitID: unitId, request: GADRequest(),
                          orientation: UIInterfaceOrientation.portrait) { [weak self] ad, error in
            if let error = error {
                self?.error = error
                completion()
                return
            }
            
            AppOpenAd.manager.amountOfAppOpens = 0
            self?.appOpenAd = ad
            self?.appOpenAd?.fullScreenContentDelegate = self
            
            completion()
            
        }
    }

    func pushMainViewController() {
        let mainViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        navigationController?.pushViewController(mainViewController, animated: false)
    }
    
    func getRemoteConfig(completion: @escaping VoidClosure) {
        let remoteConfig = RemoteConfig.remoteConfig()

        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        #endif
        
        remoteConfig.fetch { (status, error) -> Void in
          if status == .success {
            print("Config fetched!")
            remoteConfig.activate { changed, error in
              // ...
            }
          } else {
            print("Config not fetched")
            print("Error: \(error?.localizedDescription ?? "No error available.")")
          }

          completion()
        }

    }
    
}

fileprivate typealias FullScreenContentDelegate = SplashViewController
extension SplashViewController {
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
       pushMainViewController()
    }
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        
    }
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        pushMainViewController()
    }
}

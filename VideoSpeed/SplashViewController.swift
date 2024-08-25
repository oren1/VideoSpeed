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
    let amountOfRequests: Float = 4
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let minimumAppOpensToShowAd = RemoteConfig.remoteConfig().configValue(forKey: "minimumAppOpensToShowAd").numberValue.intValue

        print("minimumAppOpensToShowAd \(minimumAppOpensToShowAd)")
        
        let downloadGroup = DispatchGroup()

        Task {
            downloadGroup.enter()
            let _ = try? await SpidProducts.store.refreshPurchasedProducts()
            increaseProgress()
            downloadGroup.leave()
        }
        
        Task {
            downloadGroup.enter()
            if let benefitStatus = try? await NetworkManager.shared.getUserBenefitStatus() {
                UserDataManager.main.userBenefitStatus = benefitStatus
                increaseProgress()
                downloadGroup.leave()
            }
        }
        
        downloadGroup.enter()
        SpidProducts.store.requestProducts { [weak self] success, products in
            guard let self = self else {return}
          
            if let products = products, success {
                UserDataManager.main.products = products
                DispatchQueue.main.async {
                    self.increaseProgress()
                }
                downloadGroup.leave()
            }
            /* In case of error it means that the products were not fetched and i dont want to enter the app
               let it be stuck and the user to reload the app
             */
        }
        
        
        downloadGroup.enter()
        getRemoteConfig { [weak self] in
            guard let self = self else {return}
            increaseProgress()
            downloadGroup.leave()
        }
        
//        downloadGroup.enter()
//        loadAppOpenAdIfAppropriate(viewVontroller: self) {
//            downloadGroup.leave()
//        }
        
        
        downloadGroup.notify(queue: DispatchQueue.main) { [weak self] in
                self?.pushMainViewController()
            
//             if let appOpenAd = self?.appOpenAd,
//                let rootViewController = self?.view.window?.rootViewController {
//                 appOpenAd.present(fromRootViewController: rootViewController)
//                 return
//             }
//             else {
//                self?.pushMainViewController()
//             }
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
           
        Task {
            do {
                self.appOpenAd = try await GADAppOpenAd.load(withAdUnitID: unitId, request: GADRequest())
                self.appOpenAd?.fullScreenContentDelegate = self
                AppOpenAd.manager.amountOfAppOpens = 0
                completion()

             } catch {
                 self.error = error
                 completion()
             }
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
    
    // Increase progress for the progressView
    func increaseProgress() {
        let progress = progressView.progress + (1 / amountOfRequests)
        progressView.setProgress(progress, animated: true)
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

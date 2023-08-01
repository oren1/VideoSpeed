//
//  SplashViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import UIKit
import GoogleMobileAds

class SplashViewController: UIViewController, GADFullScreenContentDelegate {

    var appOpenAd: GADAppOpenAd?
    var adDidDismis = false
    var requestsDidFinish = false
    var error: Error?
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            
        let unitId = "ca-app-pub-5159016515859793/8839080524"
//        var testUnitId = "ca-app-pub-3940256099942544/5662855259"
        
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
    
    func getRemoteConfig() {
//        #if DEBUG
//        let settings = RemoteConfigSettings()
//        settings.minimumFetchInterval = 0
//        RemoteConfig.remoteConfig().configSettings = settings
//        #endif
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

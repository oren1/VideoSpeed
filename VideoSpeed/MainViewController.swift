//
//  MainViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 14/07/2023.
//

import UIKit
import Photos
import AdSupport
import AppTrackingTransparency
import FirebaseRemoteConfig
import SwiftUI
import RevenueCat


class MainViewController: UIViewController {
    
    // MARK: - Properties
    private let reuseIdentifier = "PhotoCell"
    private let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var videos: PHFetchResult<PHAsset>?
    private let itemsPerRow: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 3
    
    private var giftBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var giftButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var photoLibraryUsageDisabledView: PhotoLibraryUsageDisabledView = {
        photoLibraryUsageDisabledView = PhotoLibraryUsageDisabledView()
        return photoLibraryUsageDisabledView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        #if DEBUG
         print("purchased")
        #else
         print("not purchased")
        #endif
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Arial Hebrew Bold", size: 17)!]

        navigationItem.title = "SPID"
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        addProButton()
        
        PHPhotoLibrary.shared().register(self)

        getPermissionIfNecessary { granted in
              guard granted else {
                  DispatchQueue.main.async { [weak self] in
                    guard let self = self else {return}
                      self.addPhotoLibraryUsageDisabledView()
                  }
                  return
              }

              self.fetchAssets()

              DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                self.collectionView.reloadData()
              }
            }
        
        
        createGiftBarButtonItem()
        
        
    }
    
    func needsToShowGiftButton() -> Bool {
        if  SpidProducts.store.userPurchasedProVersion() == nil &&
            UserDataManager.main.userBenefitStatus == .notInvoked {
            return true
        }
        
        return false
    }
    
    func createProButton() -> UIButton {
        let proButton = UIButton(type: .roundedRect)
        proButton.tintColor = .white
        proButton.backgroundColor = .systemBlue
        proButton.setTitle("  Get Pro  ", for: .normal)
        proButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        proButton.addTarget(self, action: #selector(showPurchaseViewController), for: .touchUpInside)
        proButton.layer.cornerRadius = 10
        proButton.layer.borderWidth = 0
        proButton.layer.borderColor = UIColor.lightGray.cgColor
        return proButton
    }
    
    
    @objc func showPurchaseViewController() {
       
        let purchaseViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "YearlySubscriptionPurchaseVC") as! YearlySubscriptionPurchaseVC
        purchaseViewController.productIdentifier = SpidProducts.yearlySubscription
       
        if UIDevice.current.userInterfaceIdiom == .phone {
            purchaseViewController.modalPresentationStyle = .fullScreen
        }
        else if UIDevice.current.userInterfaceIdiom == .pad {
            purchaseViewController.modalPresentationStyle = .formSheet
        }
        
        self.present(purchaseViewController, animated: true)
    }
    
    func showBenefitView() {
        let benefitViewController = UIHostingController(rootView: BenefitView())
      
        if UIDevice.current.userInterfaceIdiom == .phone {
            benefitViewController.modalPresentationStyle = .fullScreen
        }
        else if UIDevice.current.userInterfaceIdiom == .pad {
            benefitViewController.modalPresentationStyle = .formSheet
        }
        self.present(benefitViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
       
        // Add or Remove "Get Pro" button
        if SpidProducts.store.userPurchasedProVersion() == nil &&
            UserDataManager.main.userBenefitStatus != .entitled {
            addProButton()
        }
        else {
            removeProButton()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
//            await requestPermissionForIDFAAsync()
            
//            if let lastPurchaseScreenApearance = UserDataManager.main.lastApearanceOfPurchaseScreen {
//                // 'lastApearanceOfPurchaseScreen' date exists. it means the purchase screen was already seen one or more times, so show it only if 24 hours have passed since the last apearance.
//                let now = Date().timeIntervalSince1970
//                if lastPurchaseScreenApearance + (60 * 60 * 24) < now {
//                  forceShowSplashScreen()
//                }
//            }
//            else {
//                // When there is no 'lastApearanceOfPurchaseScreen' date available it means that he purchase screen was never seen before, so show it now for the first time.
//                forceShowSplashScreen()
//            }
        }
//        requestPermissionForIDFA()
    }
    
   
    
    func requestPermissionForIDFAAsync() async {
        let status = await ATTrackingManager.requestTrackingAuthorization()
        switch status {
        case .authorized:
            // Tracking authorization dialog was shown
            // and we are authorized
            print("Authorized")
        
            // Now that we are authorized we can get the IDFA
            print(ASIdentifierManager.shared().advertisingIdentifier)
        case .denied:
           // Tracking authorization dialog was
           // shown and permission is denied
             print("Denied")
        case .notDetermined:
                // Tracking authorization dialog has not been shown
                print("Not Determined")
        case .restricted:
                print("Restricted")
        @unknown default:
                print("Unknown")
        }
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()

    }
    
    func requestPermissionForIDFA() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            guard let self = self else {return}
            switch status {
            case .authorized:
                // Tracking authorization dialog was shown
                // and we are authorized
                print("Authorized")
            
                // Now that we are authorized we can get the IDFA
                print(ASIdentifierManager.shared().advertisingIdentifier)
            case .denied:
               // Tracking authorization dialog was
               // shown and permission is denied
                 print("Denied")
            case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
            case .restricted:
                    print("Restricted")
            @unknown default:
                    print("Unknown")
            }
            

        }
    }
    deinit {
      PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func getPermissionIfNecessary(completionHandler: @escaping (Bool) -> Void) {
      // 1
      guard PHPhotoLibrary.authorizationStatus() != .authorized else {
        completionHandler(true)
        return
      }
        
      // 2
      PHPhotoLibrary.requestAuthorization { status in
         
          switch status {
          case .authorized:
              AnalyticsManager.userAuthorizedPhotoLibraryPermission()
          case .limited:
              AnalyticsManager.userLimitedPhotoLibraryPermission()
          case .denied:
              AnalyticsManager.userDeniedPhotoLibraryPermission()
          case .notDetermined:
              AnalyticsManager.userNotDeterminedPhotoLibraryPermission()
          default: break
          }
          
        completionHandler(status == .authorized)
      }
    }
    
    func fetchAssets() {
      // 1
      let allPhotosOptions = PHFetchOptions()
      allPhotosOptions.sortDescriptors = [
        NSSortDescriptor(
          key: "creationDate",
          ascending: false)
      ]
        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)

      videos = PHAsset.fetchAssets(with: allPhotosOptions)
    
    }
    
    func addPhotoLibraryUsageDisabledView() {
        view.addSubview(photoLibraryUsageDisabledView)
        photoLibraryUsageDisabledView.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            photoLibraryUsageDisabledView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            photoLibraryUsageDisabledView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            photoLibraryUsageDisabledView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            photoLibraryUsageDisabledView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)

    }

    func removePhotoLibraryUsageDisabledView() {
        photoLibraryUsageDisabledView.removeFromSuperview()
    }
    
    // MARK: - UI
    func removeProButton() {
        self.navigationItem.rightBarButtonItems = nil
    }
    func addProButton() {
        let proButton = createProButton()
        let proBarButtonItem = UIBarButtonItem(customView: proButton)
        navigationItem.rightBarButtonItems = [proBarButtonItem]
    }
    func createGiftBarButtonItem() {
        giftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gift.fill"), style: .plain, target: self, action: #selector(giftButtonTapped))
    }
    //MARK: - Actions
    
    @IBAction func giftButtonTapped(_ sender: Any) {
        AnalyticsManager.giftButtonTappedEvent()
        showBenefitView()
    }
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
        VideoHelper.startMediaBrowser(delegate: self, sourceType: .camera)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate {
    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      dismiss(animated: true, completion: nil)
      
      guard
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
        mediaType == UTType.movie.identifier,
        let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL,
        UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        else { return }
      
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
            vc.assetUrl = url
            self.navigationController?.pushViewController(vc, animated: true)
                    
    }

}

// MARK: - UINavigationControllerDelegate
extension MainViewController: UINavigationControllerDelegate {
}

// MARK: - UICollectionViewDataSource
extension MainViewController: UICollectionViewDataSource {
  // 1
   func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  // 2
   func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
      return videos?.count ?? 0
  }

  // 3
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // 1
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: reuseIdentifier,
      for: indexPath
    ) as! PhotoCell

    // 2
    // grab the photo
//    cell.backgroundColor = .green
//       cell.imageView.backgroundColor = .red
    let asset = videos![indexPath.row]
       cell.imageView.fetchImageAsset(asset, targetSize: cell.imageView.bounds.size, completionHandler: nil)
       cell.timeLabel.text = String(format: "%02d:%02d",Int((asset.duration / 60)),Int(asset.duration) % 60)
       cell.layer.cornerRadius = 8

    return cell
  }
    
    
    func collectionView(
      _ collectionView: UICollectionView,
      viewForSupplementaryElementOfKind kind: String,
      at indexPath: IndexPath
    ) -> UICollectionReusableView {
      switch kind {
      // 1
      case UICollectionView.elementKindSectionHeader:
        // 2
        let headerView = collectionView.dequeueReusableSupplementaryView(
          ofKind: kind,
          withReuseIdentifier: "\(PhotosHeader.self)",
          for: indexPath)

        // 3
        guard let typedHeaderView = headerView as? PhotosHeader
        else { return headerView }

        // 4
          let triangle: String = "\u{25BC}"
        typedHeaderView.label.text = "Recents"
          typedHeaderView.triangleLabel.text = "\(triangle)"
        return typedHeaderView
      default:
          let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "\(PhotosHeader.self)",
            for: indexPath)
          headerView.frame.size.height = 0.0
          return headerView
//        assert(false, "Invalid element type")
      }
    }

}

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        let video = videos![indexPath.row]
        
        video.getAVAssetUrl { [weak self] progress, error, stop, info in
            DispatchQueue.main.async {
                let loadingView = self?.view.viewWithTag(loadinViewTag)
                if loadingView == nil && progress != 1 {
                    self?.showLoading()
                }
                print("progress \(progress)")
            }
        } completionHandler: { responseURL, asset in
            DispatchQueue.main.async { [weak self] in
                self?.hideLoading()
//                vc.assetUrl = responseURL
                Task {
//                    let rotatedAsset = await asset?.rotateVideoToIntendedOrientation()
                    vc.asset = asset
                    self?.navigationController?.pushViewController(vc, animated: true)

                }
            }
        }
    }
}


// MARK: - Collection View Flow Layout Delegate
extension MainViewController: UICollectionViewDelegateFlowLayout {
  // 1
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    // 2
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    return CGSize(width: widthPerItem, height: widthPerItem)
  }

  // 3
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    return sectionInsets
  }

  // 4
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    return sectionInsets.left
  }
}

extension MainViewController: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
      
    guard let videos = videos,
          let change = changeInstance.changeDetails(for: videos) else {return}
      
    DispatchQueue.main.sync { [weak self] in
        self?.videos = change.fetchResultAfterChanges
        self?.collectionView.reloadData()
    }
  }
}

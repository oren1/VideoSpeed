//
//  IAPManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 21/07/2023.
//

import Foundation

import Foundation
import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
    static let IAPManagerPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
    static let IAPManagerRestoreNotification = Notification.Name("IAPManagerRestoreNotification")
    static let IAPManagerPurchaseFailedNotification = Notification.Name("IAPManagerPurchaseFailedNotification")
}


class SpidProducts {
    
    static let everyMonthSubscription = "monthly_subscription"
    static let everyYearSubscription = "yearly_subscription"

    private static let productIdentifiers: Set<ProductIdentifier> = [SpidProducts.everyMonthSubscription, SpidProducts.everyYearSubscription]
    
    static let store = IAPManager(productIds: productIdentifiers)

}


class IAPManager: NSObject {
    
        private let productIdentifiers: Set<ProductIdentifier>
        private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
        private var productsRequest: SKProductsRequest?
        private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?

    
        public init(productIds: Set<ProductIdentifier>) {
          productIdentifiers = productIds
          for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
              purchasedProductIdentifiers.insert(productIdentifier)
              print("Previously purchased: \(productIdentifier)")
            } else {
              print("Not purchased: \(productIdentifier)")
            }
          }
            
          super.init()
          SKPaymentQueue.default().add(self)

        }

    
    public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) {
      productsRequest?.cancel()
      productsRequestCompletionHandler = completionHandler

      productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
      productsRequest!.delegate = self
      productsRequest!.start()
    }

    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
      return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public func buyProduct(_ product: SKProduct) {
      print("Buying \(product.productIdentifier)...")
      let payment = SKPayment(product: product)
      SKPaymentQueue.default().add(payment)
    }
    
    public func restorePurchases() {
      SKPaymentQueue.default().restoreCompletedTransactions()
    }

    public func canMakePayments() -> Bool {
      return SKPaymentQueue.canMakePayments()
    }
    
    
    func updateIAPStatusForAppleReceit(json: [String: Any], userDefaults: UserDefaults) {
        
        guard let latestReceiptInfo = json["latest_receipt_info"] as? [[String: Any]] else {
            // If the 'latest_receipt_info' array is missing then there is no subscriptions purchased
            purchasedProductIdentifiers.removeAll()
            userDefaults.removeObject(forKey: SpidProducts.everyMonthSubscription)
            userDefaults.removeObject(forKey: SpidProducts.everyYearSubscription)
            return print("Error: No 'latest_receipt_info' array, no subscription purchased")
        }
        
        
        // 1.Loop trough the product identifiers array
        // 2.From the "latest_receipt_info" array try to find a purchase object with the current 'productId'
        // that has not expired yet (expiration date is in the future)
        // 3.If there is at least one valid purchase, then the purchase is valid and we don't need
        // to change it's status in UserDefaults, the status remains 'true'
       
        // 1.
        for productId in productIdentifiers {

            // 2.
            let productValidPurchases = latestReceiptInfo.filter({ (purchase) -> Bool in
                guard let product_id = purchase["product_id"] as? String,
                      let purchaseExpirationString = purchase["expires_date_ms"] as? String else { return false  }

                let now = Date().timeIntervalSince1970
                let purchaseExpirationDate = Double(purchaseExpirationString)! / 1000
                
                
                return (productId == product_id) && (purchaseExpirationDate > now)
            })
            
            
            if productValidPurchases.count > 0 {
                purchasedProductIdentifiers.insert(productId)
                userDefaults.set(true, forKey: productId)
            }
            else {
                purchasedProductIdentifiers.remove(productId)
                userDefaults.set(false, forKey: productId)
            }
            
        }
    }
        
    
    enum IAPManagerError: Error {
        case noProductIDsFound
        case noProductsFound
        case paymentWasCancelled
        case productRequestFailed
    }
    
    func getPriceFormatted(for product: SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
    
}


extension IAPManager.IAPManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noProductIDsFound: return "No In-App Purchase product identifiers were found."
        case .noProductsFound: return "No In-App Purchases were found."
        case .productRequestFailed: return "Unable to fetch available In-App Purchase products at the moment."
        case .paymentWasCancelled: return "In-App Purchase process was cancelled."
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {

  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    print("Loaded list of products...")
    let products = response.products
    productsRequestCompletionHandler?(true, products)
    clearRequestAndHandler()

    for p in products {
      print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
    }
  }
  
  public func request(_ request: SKRequest, didFailWithError error: Error) {
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
    productsRequestCompletionHandler?(false, nil)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
    productsRequest = nil
    productsRequestCompletionHandler = nil
  }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
 
  public func paymentQueue(_ queue: SKPaymentQueue,
                           updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        complete(transaction: transaction)
        break
      case .failed:
        fail(transaction: transaction)
        break
      case .restored:
        restore(transaction: transaction)
        break
      case .deferred:
        break
      case .purchasing:
        break
      @unknown default:
          fatalError()
      }
    }
  }
 
  private func complete(transaction: SKPaymentTransaction) {
    print("complete...")
    deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func restore(transaction: SKPaymentTransaction) {
    guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
    print("restore... \(productIdentifier)")
    deliverRestoreNotificationFor(identifier: productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func fail(transaction: SKPaymentTransaction) {
    print("fail...")
    if let _ = transaction.error as NSError?,
      let localizedDescription = transaction.error?.localizedDescription {
        print("Transaction Error: \(localizedDescription)")
        NotificationCenter.default.post(name: .IAPManagerPurchaseFailedNotification, object: localizedDescription)
      }

    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func deliverPurchaseNotificationFor(identifier: String?) {
    guard let identifier = identifier else { return }
    updateIdentifier(identifier: identifier)
    NotificationCenter.default.post(name: .IAPManagerPurchaseNotification, object: identifier)
  }
    
  private func deliverRestoreNotificationFor(identifier: String?) {
    guard let identifier = identifier else { return }
    updateIdentifier(identifier: identifier)
    NotificationCenter.default.post(name: .IAPManagerRestoreNotification, object: identifier)
  }
    
    
    func updateIdentifier(identifier: String) {
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
    }
}


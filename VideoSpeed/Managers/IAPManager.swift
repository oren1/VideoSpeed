//
//  IAPManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 21/07/2023.
//

import Foundation

import Foundation
import StoreKit

enum StoreError: Int {
    case paymentCancelled = 2
}

enum RefreshPurchasesStatus {
    case noPurchasesFound, foundActivePurchase
}

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
    static let IAPManagerPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
    static let IAPManagerRestoreNotification = Notification.Name("IAPManagerRestoreNotification")
    static let IAPManagerPurchaseFailedNotification = Notification.Name("IAPManagerPurchaseFailedNotification")
}


class SpidProducts {
    
    static let proVersion = "com.spid.app.pro"
    static let proVersionTenDollars = "ProVersion.9"
    static let monthlySubscription = "Monthly.Subscription"
    static let yearlySubscription = "Yearly.Subscription"
    static let yearlySubscriptionTakeTwo = "Yearly.Subscription.15"
    static let proVersionConsumable = "ProVersion345"
    static let monthlySubscriptionFive = "Monthly.Subscription.Five"
    static let weeklySubscription = "Weekly.Subscription.Spid"
    static let yearlyFifteen = "Yearly.Subscription.Fifteen"
    static let yearlyTwenty = "Yearly.19"


    private static let productIdentifiers: Set<ProductIdentifier> = [proVersion, proVersionTenDollars, proVersionConsumable,monthlySubscription,yearlySubscription,yearlySubscriptionTakeTwo,monthlySubscriptionFive,weeklySubscription,yearlyFifteen,yearlyTwenty]
    
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
//          SKPaymentQueue.default().add(self)

        }

    func getProductIdentifiers() -> Set<ProductIdentifier> {
        return productIdentifiers
    }
    
    func getPurchasedProductIdentifiers() -> Set<ProductIdentifier> {
        return purchasedProductIdentifiers
    }
    
    public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) {
      productsRequest?.cancel()
      productsRequestCompletionHandler = completionHandler

      productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
      productsRequest!.delegate = self
      productsRequest!.start()
    }

    func userPurchasedProVersion() -> ProductIdentifier? {
//        #if DEBUG
//            // this string doesn't mean anything, i just return it so the return value
//            // won't be null
//            return "test_identifier"
//        #else
            if let purchasedProduct = productIdentifiers.first(where: { productIdentifier in
                return isProductPurchased(productIdentifier)
            }) {
                return purchasedProduct
            }
            
            return nil
//        #endif
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
      return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public func buyProduct(_ product: SKProduct) {
      print("Buying \(product.productIdentifier)...")
      let payment = SKPayment(product: product)
      SKPaymentQueue.default().add(payment)
    }
    
    
    func refreshPurchasedProducts() async throws -> RefreshPurchasesStatus {
        // Iterate through the user's purchased products.
        let products = try await Product.products(for: SpidProducts.store.getProductIdentifiers())
        var verifiedActiveTransactions: [Transaction] = []
        
        for product in products {
//            if let status = try await product.subscription?.status {
//                for stat in status {
//                    print("state \(stat.state)")
//
//                    if stat.state == .inBillingRetryPeriod {
//                        print ("inBillingRetryPeriod")
//                    }
//                    else if stat.state == .inGracePeriod {
//                        print ("inGracePeriod")
//                    }
//                    else if stat.state == .expired {
//                        print("expired")
//                    }
//                }
//            }
            
            guard let verificationResult = await product.currentEntitlement else {
                
                SpidProducts.store.removeProductEntitlement(productIdentifier: product.id)
                continue
            }


            switch verificationResult {
            case .verified(let transaction):
                // Check the transaction and give the user access to purchased
                // content as appropriate.
                print("transaction \(transaction)")
                SpidProducts.store.updateIdentifier(identifier: transaction.productID)
                verifiedActiveTransactions.append(transaction)
            case .unverified(let transaction, let verificationError):
                print("verificationError", verificationError)
                print("verificationError transaction", transaction)
            }
        }
    
        if verifiedActiveTransactions.count > 0 {return RefreshPurchasesStatus.foundActivePurchase}
        return RefreshPurchasesStatus.noPurchasesFound
    }
    
//    public func restorePurchases() async throws ->  {
//        try await AppStore.sync() // syncs all transactions from the appstore
//        let refreshStatus =  try await SpidProducts.store.refreshPurchasedProducts()
//        return refreshStatus
//    }

    public func canMakePayments() -> Bool {
      return SKPaymentQueue.canMakePayments()
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
    
    func removeProductEntitlement(productIdentifier: ProductIdentifier) {
        purchasedProductIdentifiers.remove(productIdentifier)
        UserDefaults.standard.removeObject(forKey: productIdentifier)
    }
    
    func updateIdentifier(identifier: String) {
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
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



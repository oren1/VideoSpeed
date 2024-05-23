//
//  NetworkManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 16/05/2024.
//

import Foundation
import Combine
import UIKit

enum BenefitStatus: String {
    case notInvoked = "notInvoked"
    case entitled = "entitled"
    case expired = "expired"
}

enum BenefitServiceError: Error {
    case benefitStatusNotDetermined
    case generalError(message: String)
}

class NetworkManager {
    #if DEBUG
    let benefitServiceUrl = "https://us-central1-staging-benefit-service-spid.cloudfunctions.net/spid"
    #else
    let benefitServiceUrl = "https://us-central1-benefit-service-spid.cloudfunctions.net/spid"
    #endif
    
    static var shared = NetworkManager()
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getUserBenefitStatus() async throws -> BenefitStatus {
        // get the user vendor UUID
        let userId = await UIDevice.current.identifierForVendor!.uuidString
        print("user id: \(userId)")
        let body = ["userId": userId]
        
        
        let urlString = benefitServiceUrl + "/users/\(userId)/benefitstatus"
        let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        var request = URLRequest(url: URL(string: encodedURLString)!)
        request.httpMethod = "GET"
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        let response = try decoder.decode(Response<User>.self, from: data)
        if response.success {
            if let benefitStatus = BenefitStatus(rawValue: response.data.benefitStatus) {
                return benefitStatus
            }
            throw BenefitServiceError.benefitStatusNotDetermined
        }
        else {
            throw BenefitServiceError.generalError(message: response.message)

        }
    }
    
    
    func createUser() async throws {
        // get the user vendor UUID
        let userId = await UIDevice.current.identifierForVendor!.uuidString
        print("user id: \(userId)")
        let body = ["userId": userId]
        let bodyData = try? JSONSerialization.data(
            withJSONObject: body,
            options: []
        )
        
        var request = URLRequest(url: URL(string: benefitServiceUrl + "/users")!)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        let response = try decoder.decode(Response<User>.self, from: data)
        if response.success {
            if let benefitStatus = BenefitStatus(rawValue: response.data.benefitStatus) {
                UserDataManager.main.userBenefitStatus = benefitStatus
                return
            }
            throw BenefitServiceError.benefitStatusNotDetermined
        }
        else {
            throw BenefitServiceError.generalError(message: response.message)

        }
    }
}

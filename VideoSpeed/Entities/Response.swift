//
//  Response.swift
//  VideoSpeed
//
//  Created by oren shalev on 16/05/2024.
//

import Foundation


struct Response<T: Codable>: Codable {
  
    var success: Bool
    var message: String
    var data: T?
    
    enum CodingKeys: String, CodingKey {
           case success = "success"
           case message = "message"
           case data = "data"
       }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            success = try container.decode(Bool.self, forKey: .success)
            message = try container.decode(String.self, forKey: .message)
            if let data = try? container.decode(T.self, forKey: .data) {
                self.data = data
            }
            else {
                data = nil
            }
        }
    
}

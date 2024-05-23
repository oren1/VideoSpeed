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
    var data: T
}

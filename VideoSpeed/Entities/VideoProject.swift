//
//  VideoProject.swift
//  VideoSpeed
//

import Foundation
import SwiftData

@Model
final class VideoProject {
    var speed: Float

    init(speed: Float = 1.0) {
        self.speed = speed
    }
}

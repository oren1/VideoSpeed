//
//  CGSize+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/06/2025.
//

import Foundation

enum SizeOrientation {
    case portrait, landscape
}

extension CGSize {
    func orientation() -> SizeOrientation {
        let aspectRatio = self.width / self.height
        if aspectRatio < 1 { return SizeOrientation.portrait }
        else { return SizeOrientation.landscape }
    }
}

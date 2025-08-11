//
//  MenuItem.swift
//  VideoSpeed
//
//  Created by oren shalev on 26/01/2025.
//



enum ItemId {
    case speed, trim, crop, captions, fps, sound, text, more
}

struct MenuItem: Equatable {
    let id: ItemId
    let title: String
    let imageName: String
    
    static func ==(lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.id == rhs.id
    }
}

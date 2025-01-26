//
//  MenuItem.swift
//  VideoSpeed
//
//  Created by oren shalev on 26/01/2025.
//



enum ItemId {
    case speed, trim, crop, fps, sound, more
}

struct MenuItem {
    let id: ItemId
    let title: String
}

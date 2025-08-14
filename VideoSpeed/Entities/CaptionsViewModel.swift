//
//  CaptionsViewModel.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 13/08/2025.
//

import SwiftUI
import Combine

class CaptionsViewModel: ObservableObject {
    
    @Published var captions: [CaptionItem] = []
    @Published var lastEditedCaption: CaptionItem?
    
    init(captions: [CaptionItem], lastEditedCaption: CaptionItem? = nil) {
        self.captions = captions
        self.lastEditedCaption = lastEditedCaption
    }
    
    
    // Called when the edit button is tapped
    func editCaption(_ caption: CaptionItem, newText: String? = nil) {
            lastEditedCaption = caption
        }
}


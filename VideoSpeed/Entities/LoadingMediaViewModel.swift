//
//  LoadingMediaViewModel.swift
//  VideoSpeed
//
//  Created by oren shalev on 05/12/2024.
//

import Foundation

class LoadingMediaViewModel: ObservableObject {
    @Published var progress: Float = 0
    @Published var showProgress: Bool = true
    @Published var title: String?
}

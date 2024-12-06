//
//  LoadingMediaView.swift
//  VideoSpeed
//
//  Created by oren shalev on 30/11/2024.
//

import SwiftUI

struct LoadingMediaView: View {
    
    @ObservedObject var loadingMediaViewModel: LoadingMediaViewModel
    
    var body: some View {
        ZStack {

            Color.black.opacity(0.6)
                .ignoresSafeArea()
            Text("Preparing Video For Crop \(Int(loadingMediaViewModel.progress * 100)) %")
                .foregroundStyle(.white)
        
        }
    }
}



#Preview {
    LoadingMediaView(loadingMediaViewModel: LoadingMediaViewModel())
}

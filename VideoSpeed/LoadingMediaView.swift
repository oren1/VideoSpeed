//
//  LoadingMediaView.swift
//  VideoSpeed
//
//  Created by oren shalev on 30/11/2024.
//

import SwiftUI

struct LoadingMediaView: View {
    var body: some View {
        ZStack {

            Color.black.opacity(0.6)
                .ignoresSafeArea()
            Text("Preparing Media For Crop")
                .foregroundStyle(.white)
        
        
        }
    }
}



#Preview {
    LoadingMediaView()
}

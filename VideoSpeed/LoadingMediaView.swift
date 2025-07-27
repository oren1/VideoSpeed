//
//  LoadingMediaView.swift
//  VideoSpeed
//
//  Created by oren shalev on 30/11/2024.
//

import SwiftUI
import ActivityIndicatorView

struct LoadingMediaView: View {
    
    @ObservedObject var loadingMediaViewModel: LoadingMediaViewModel
    @State var isActivityIndicatorVisible = true
    
    var body: some View {
        ZStack {

            Color.black.opacity(0.6)
                .ignoresSafeArea()
            VStack(alignment: .center) {
                Text("Cropping Video")
                    .foregroundStyle(.white)
                    .padding(.bottom)
                ZStack {
                    ActivityIndicatorView(isVisible: $isActivityIndicatorVisible, type: .gradient([.white, Color(cgColor: UIColor.systemBlue.cgColor)], lineWidth: 2))
                        .frame(width: 100, height: 100)
                    Text("\(Int(loadingMediaViewModel.progress * 100))%")
                        .foregroundStyle(.white)
                        .padding(.leading, 8)
                }
                

            }
            
        
        }
    }
}



#Preview {
    LoadingMediaView(loadingMediaViewModel: LoadingMediaViewModel())
}

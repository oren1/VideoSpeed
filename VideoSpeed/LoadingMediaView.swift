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
                let title = loadingMediaViewModel.title ?? "Loding..."
                Text(title)
                    .foregroundStyle(.white)
                    .padding(.bottom)
                ZStack {
                    ActivityIndicatorView(isVisible: $isActivityIndicatorVisible, type: .gradient([.white, Color(cgColor: UIColor.systemBlue.cgColor)], lineWidth: 2))
                        .frame(width: 100, height: 100)
                    if loadingMediaViewModel.showProgress {
                        Text("\(Int(loadingMediaViewModel.progress * 100))%")
                            .foregroundStyle(.white)
                            .padding(.leading, 8)
                    }
                    
                }
                

            }
            
        
        }
    }
}


func loadingMediaViewPreview() -> some View {
    let loadingMediaViewModel = LoadingMediaViewModel()
    loadingMediaViewModel.showProgress = false
    loadingMediaViewModel.progress = 0.5
    loadingMediaViewModel.title = "Transcribing Audio..."
    return LoadingMediaView(loadingMediaViewModel: loadingMediaViewModel)
}

#Preview {
    loadingMediaViewPreview()
}

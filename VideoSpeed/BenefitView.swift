//
//  BenefitView.swift
//  VideoSpeed
//
//  Created by oren shalev on 12/05/2024.
//

import SwiftUI

struct BenefitView: View {
    @State private var isPresented = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {

                Color.black.opacity(1)
                               .ignoresSafeArea()
                VStack {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue)
                        .padding(.top, 50)
                        .padding(.bottom, 20)
                    
                    Text("3 Months Free")
                        .foregroundStyle(.white)
                        .font(.system(size: 34, weight: .bold))

                    Text("Share With Your Friends\n And Get All Features\n Free For 3 Months")
                        .lineSpacing(10)
                        .padding([.horizontal])
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 10)
                    
                   
                    Spacer()

                    VStack {
                        Button(action: {
                            isPresented.toggle()
                            AnalyticsManager.shareButtonTappedEvent()
                        }, label: {
                            Spacer()
                            Text("Share")
                                .font(.system(size: 22, weight: .semibold))
                            Spacer()
                        })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(.blue)
                        .clipShape(Capsule())
                        
                        Button(action: {
                            AnalyticsManager.laterButtonTappedEvent()
                            dismiss()
                        }, label: {
                            Spacer()
                            Text("Later")
                                .font(.system(size: 22, weight: .semibold))
                            Spacer()
                        })
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 35)
                    .sheet(isPresented: $isPresented, content: {
                           if #available(iOS 16, *) {
                                ActivityViewController(showAlert: $showAlert, alertMessage: $alertMessage, isLoading: $isLoading)
                                 .presentationDetents([.medium])
                             }
                            else {
                                ActivityViewController(showAlert: $showAlert, alertMessage: $alertMessage, isLoading: $isLoading)
                            }
                    })
                }

            if isLoading {
                Color.black.opacity(0.6)
                               .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0, anchor: .center) // Makes the spinner larger
            }
        }
        .onAppear(perform: {
            AnalyticsManager.benefitViewApearEvent()
        })
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text(alertMessage), dismissButton: .default(Text("OK"), action: {
                dismiss()
            }))
        })
    }
}

struct BenefitNotInvokedView: View {
    var body: some View {
        Color.red.opacity(1)
                       .ignoresSafeArea()
    }
}

struct BenefitEntitledView: View {
    var body: some View {
        Color.green.opacity(1)
                       .ignoresSafeArea()
    }
}

#Preview {
    BenefitView()
}

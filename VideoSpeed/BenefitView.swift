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
    
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            
            Color.green.opacity(1)
                           .ignoresSafeArea()
            if UserDataManager.main.userBenefitStatus == .entitled {
                BenefitNotInvokedView()
            }
            else {
                BenefitEntitledView()
            }
//            if UserDataManager.main.userBenefitStatus == .entitled {
//                Color.black.opacity(1)
//                               .ignoresSafeArea()
//                VStack {
//                    Image(systemName: "gift.fill")
//                        .font(.system(size: 100))
//                        .foregroundStyle(.blue)
//                        .padding(.top, 50)
//                        .padding(.bottom, 20)
//                    
//                    Text("1 Month Free")
//                        .foregroundStyle(.white)
//                        .font(.system(size: 34, weight: .bold))
//
//                    Text("Invite Your Friends\n And Get All Features\n Free For 1 Month.")
//                        .lineSpacing(10)
//                        .padding([.horizontal])
//                        .multilineTextAlignment(.center)
//                        .font(.system(size: 22, weight: .bold))
//                        .foregroundStyle(.white)
//                        .padding(.top, 10)
//                    
//                   
//                    Spacer()
//
//                    VStack {
//                        Button(action: {
//                            isPresented.toggle()
//                        }, label: {
//                            Spacer()
//                            Text("Invite")
//                                .font(.system(size: 22, weight: .semibold))
//                            Spacer()
//                        })
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(.white)
//                        .clipShape(Capsule())
//                        
//                        Button(action: {
//                            dismiss()
//                        }, label: {
//                            Spacer()
//                            Text("Later")
//                                .font(.system(size: 22, weight: .semibold))
//                            Spacer()
//                        })
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(.gray)
//                        .clipShape(Capsule())
//                    }
//                    .padding(.horizontal, 25)
//                    .padding(.bottom, 35)
//                    .sheet(isPresented: $isPresented, content: {
//                        ActivityViewController(showAlert: $showAlert, alertMessage: $alertMessage)
//                    })
//                    
//                    
//                }
//            }
            
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Title"), message: Text(alertMessage), dismissButton: .cancel())

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

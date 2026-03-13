//
//  GiftPopupView.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 05/02/2026.
//


import SwiftUI

struct GiftPopupView: View {

    let daysFree: Int
    let onDismiss: () -> Void

    @State private var showPopup = false

    var body: some View {
        ZStack {
            // Background
            Color.black
                .opacity(showPopup ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 16) {
                Text("🎁 Gift Claimed!")
                    .font(.system(size: 22, weight: .bold))

                Text("You now have \(daysFree) days of free premium access.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)

                
                Button(action: {
                    dismiss()
                }) {
                    Text("OK")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .contentShape(Rectangle()) // 👈 makes entire area tappable
                }

            }
            .padding(24)
            .frame(maxWidth: 300)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .scaleEffect(showPopup ? 1.0 : 0.85)
            .opacity(showPopup ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4,
                                  dampingFraction: 0.8,
                                  blendDuration: 0.3)) {
                showPopup = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            showPopup = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

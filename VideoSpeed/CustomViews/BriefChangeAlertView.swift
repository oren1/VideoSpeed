//
//  BriefChangeAlertView.swift
//  VideoSpeed
//

import SwiftUI

struct BriefChangeAlertView: View {
    let message: String
    var size: CGSize = CGSize(width: 180, height: 56)

    var body: some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(width: size.width, height: size.height)
            .background(Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .offset(y: -50)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        BriefChangeAlertView(message: "speed: 1.5", size: CGSize(width: 180, height: 56))
    }
}

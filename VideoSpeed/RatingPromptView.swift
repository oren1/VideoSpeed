//
//  RatingPromptView.swift
//  VideoSpeed
//
//  Created by AI on 17/02/2026.
//

import SwiftUI

struct RatingPromptView: View {
    let onPositive: () -> Void
    let onNegative: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon + short tagline
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Text(NSLocalizedString("⭐", comment: "Rating prompt title"))
//                        .font(.largeTitle)
                        .font(.system(size: 54, weight: .bold))
                        .multilineTextAlignment(.center)
//                    Image(systemName: "star.circle.fill")
//                        .font(.system(size: 44))
//                        .foregroundStyle(Color.accentColor)
                }
                Text(NSLocalizedString("Enjoying Spid?", comment: "Rating prompt title"))
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            Text(NSLocalizedString("If you’re finding it useful, we’d really appreciate a quick rating. It helps us keep improving!", comment: "Rating prompt body"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 12) {
                Button(action: onPositive) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.subheadline.weight(.semibold))
                        Text(NSLocalizedString("Yes, it's great", comment: "Positive rating gate button"))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button(action: onNegative) {
                    Text(NSLocalizedString("Not really", comment: "Negative rating gate button"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
    }
    
    
}


#Preview {
    RatingPromptView(onPositive: {}, onNegative: {})
}

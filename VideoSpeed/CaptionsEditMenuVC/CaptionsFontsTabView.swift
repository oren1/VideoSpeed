//
//  CaptionsFontsTabView.swift
//  VideoSpeed
//
//  Created by Codex on 21/04/2026.
//

import SwiftUI

struct CaptionsFontsTabView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Fonts")
                .font(.title3.weight(.semibold))
            Text("Font options will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CaptionsFontsTabView()
}

//
//  CaptionsStylesTabView.swift
//  VideoSpeed
//
//  Created by Codex on 21/04/2026.
//

import SwiftUI

struct CaptionsStylesTabView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Styles")
                .font(.title3.weight(.semibold))
            Text("Style controls will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CaptionsStylesTabView()
}

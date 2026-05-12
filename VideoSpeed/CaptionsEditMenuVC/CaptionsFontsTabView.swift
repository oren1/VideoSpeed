//
//  CaptionsFontsTabView.swift
//  VideoSpeed
//
//  Created by Codex on 21/04/2026.
//

import SwiftUI

struct CaptionsFontsTabView: View {
    @ObservedObject private var captionsStyle: CaptionsStyle

    private let gridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 140), spacing: 12)
    ]

    @State private var fonts: [SpidFont] = []

    init() {
        _captionsStyle = ObservedObject(wrappedValue: CaptionStyleGenerator.captionsStyle)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(fonts, id: \.name) { spidFont in
                    fontCell(spidFont)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if fonts.isEmpty {
                fonts = SpidFont.loadAllPrioritized(size: 16)
            }
        }
    }

    @ViewBuilder
    private func fontCell(_ spidFont: SpidFont) -> some View {
        let selected = isSelected(spidFont)
        Button {
            applyFont(spidFont)
        } label: {
            VStack(spacing: 6) {
                VStack(spacing: 4) {
                    Text("Aa")
                        .font(Font(spidFont.font ?? .systemFont(ofSize: 22)))
                        .foregroundStyle(.primary)

                    Text(spidFont.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ spidFont: SpidFont) -> Bool {
        spidFont.name == CaptionStyleGenerator.captionsStyle.spidFont.name
    }

    private func applyFont(_ spidFont: SpidFont) {
        CaptionStyleGenerator.captionsStyle.spidFont = SpidFont(
            name: spidFont.name,
            displayName: spidFont.displayName,
            font: nil,
            isPro: spidFont.isPro
        )
    }
}

#Preview {
    CaptionsFontsTabView()
}

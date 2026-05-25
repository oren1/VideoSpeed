//
//  CaptionsTemplatesTabView.swift
//  VideoSpeed
//
//  Created by Codex on 21/04/2026.
//

import SwiftUI

struct CaptionsTemplatesTabView: View {
    let onSelect: (CaptionsType) -> Void
    @State private var selectedType: CaptionsType = .oneWord

    init(onSelect: @escaping (CaptionsType) -> Void = { _ in }) {
        self.onSelect = onSelect
    }

    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let previewTranscription = Segment.demoTranscription()

    private let templateOptions: [(title: String, type: CaptionsType)] = [
        ("One Word", .oneWord),
        ("Word By Word", .wordByWord),
        ("Word Highlighted", .wordHighlighted),
        ("Full Line", .fullLine)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(templateOptions, id: \.title) { option in
                    Button {
                        selectedType = option.type
                        onSelect(option.type)
                    } label: {
                        VStack(spacing: 8) {
                            CaptionsTemplatePreviewView(
                                captionsType: option.type,
                                transcription: previewTranscription
                            )
                            .frame(height: 120)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        selectedType == option.type ? Color.accentColor : Color.clear,
                                        lineWidth: 2
                                    )
                            }

                            Text(option.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedType == option.type ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            selectedType = CaptionStyleGenerator.captionsStyle.captionType
        }
    }
}

#Preview {
    CaptionsTemplatesTabView()
}

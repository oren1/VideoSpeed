//
//  AudioImportOptionsSheetView.swift
//  VideoSpeed
//

import SwiftUI

struct AudioImportOptionsSheetView: View {
    let onSelect: (AudioImportOption) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Audio")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.top, 12)

            VStack(spacing: 0) {
                ForEach(Array(AudioImportOption.allCases.enumerated()), id: \.element.id) { index, option in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 52)
                    }
                    optionRow(option)
                }
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Spacer(minLength: 0)
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    private var cardBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    private func optionRow(_ option: AudioImportOption) -> some View {
        Button {
            onSelect(option)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.systemImageName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                Text(option.rawValue)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AudioImportOptionsSheetView(onSelect: { _ in }, onCancel: {})
}

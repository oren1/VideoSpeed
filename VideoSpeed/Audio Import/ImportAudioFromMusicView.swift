//
//  ImportAudioFromMusicView.swift
//  VideoSpeed
//

import SwiftUI

struct ImportAudioFromMusicView: View {
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "music.note")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Import from iTunes")
                    .font(.title3.weight(.semibold))

                Text("Music library import is coming soon.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Import from iTunes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onCancel() }
                }
            }
        }
    }
}

#Preview {
    ImportAudioFromMusicView(onCancel: {})
}

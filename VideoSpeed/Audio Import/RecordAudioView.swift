//
//  RecordAudioView.swift
//  VideoSpeed
//

import SwiftUI

struct RecordAudioView: View {
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Record Audio")
                    .font(.title3.weight(.semibold))

                Text("Audio recording is coming soon.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Record")
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
    RecordAudioView(onCancel: {})
}

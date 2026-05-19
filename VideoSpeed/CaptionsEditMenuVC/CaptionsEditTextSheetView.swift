//
//  CaptionsEditTextSheetView.swift
//  VideoSpeed
//
//  Created by Codex on 10/05/2026.
//

import SwiftUI

/// Sheet for reviewing and editing transcription segments.
struct CaptionsEditTextSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userData = UserDataManager.main

    @State private var segmentTexts: [String] = []
    @State private var activeSegmentIndex: Int?
    @FocusState private var focusedSegmentIndex: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if segmentTexts.isEmpty {
                        emptyState
                    } else {
                        segmentList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Edit captions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        applyPendingSegmentEdits()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: syncSegmentTextsFromTranscription)
        .onReceive(NotificationCenter.default.publisher(for: .captionsPlaybackTimeDidChange)) { notification in
            guard let time = notification.userInfo?[CaptionsPlaybackTimeNotification.currentTimeKey] as? Double else {
                return
            }
            updateActiveSegment(for: time)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "text.bubble")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No transcript yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Transcribe your video to edit caption text here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var segmentList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(segmentTexts.enumerated()), id: \.offset) { index, _ in
                        segmentRow(index: index)
                            .id(index)
                        if index < segmentTexts.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.12))
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .onChange(of: activeSegmentIndex) { _, newIndex in
                scrollToActiveSegment(newIndex, proxy: proxy)
            }
            .onChange(of: focusedSegmentIndex) { oldFocused, focusedIndex in
                if let oldFocused, oldFocused != focusedIndex {
                    applySegmentEdit(at: oldFocused)
                }
                guard focusedIndex == nil else { return }
                scrollToActiveSegment(activeSegmentIndex, proxy: proxy)
            }
        }
    }

    private func scrollToActiveSegment(_ index: Int?, proxy: ScrollViewProxy) {
        guard let index, focusedSegmentIndex == nil else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo(index, anchor: .top)
        }
    }

    private func segmentRow(index: Int) -> some View {
        let startTime = userData.transcription?.segments?[index].start ?? 0
        let isPlayingSegment = activeSegmentIndex == index
        let isActive = focusedSegmentIndex == nil && isPlayingSegment

        return HStack(alignment: .center, spacing: 12) {
            Button {
                // Preview playback — not wired yet
            } label: {
                Image(systemName: isPlayingSegment ? "pause.fill" : "play.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Text(formatTimestamp(startTime))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .monospacedDigit()
                .frame(width: 44, alignment: .leading)

            TextField("Caption text", text: segmentTextBinding(index: index), axis: .vertical)
                .font(.body)
                .foregroundStyle(.white)
                .lineLimit(1...6)
                .textInputAutocapitalization(.sentences)
                .focused($focusedSegmentIndex, equals: index)
                .padding(.vertical, 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(isActive ? Color.white.opacity(0.08) : Color.clear)
    }

    private func segmentTextBinding(index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < segmentTexts.count else { return "" }
                return segmentTexts[index]
            },
            set: { newValue in
                guard index < segmentTexts.count else { return }
                segmentTexts[index] = newValue
            }
        )
    }

    private func syncSegmentTextsFromTranscription() {
        segmentTexts = userData.transcription?.segments?.map(\.text) ?? []
        activeSegmentIndex = nil
    }

    private func applyPendingSegmentEdits() {
        guard var transcription = userData.transcription else { return }
        var didChange = false
        for index in segmentTexts.indices {
            guard let segments = transcription.segments,
                  index < segmentTexts.count,
                  segmentTexts[index] != segments[index].text,
                  let updated = transcription.replacingSegment(at: index, editedText: segmentTexts[index])
            else { continue }
            transcription = updated
            segmentTexts[index] = updated.segments?[index].text ?? segmentTexts[index]
            didChange = true
        }
        guard didChange else { return }
        commitTranscription(transcription)
    }

    private func applySegmentEdit(at index: Int) {
        guard var transcription = userData.transcription,
              let segments = transcription.segments,
              index >= 0,
              index < segments.count,
              index < segmentTexts.count else { return }

        let editedText = segmentTexts[index]
        guard editedText != segments[index].text,
              let updated = transcription.replacingSegment(at: index, editedText: editedText) else { return }

        segmentTexts[index] = updated.segments?[index].text ?? editedText
        commitTranscription(updated)
    }

    private func commitTranscription(_ transcription: Transcription) {
        userData.transcription = transcription
        guard let segments = transcription.segments else { return }
        userData.currentCaptions = CaptionStyleGenerator.generateCaptions(from: segments)
    }

    private func updateActiveSegment(for time: Double) {
        guard let segments = userData.transcription?.segments, !segments.isEmpty else { return }
        let index = segmentIndex(for: time, in: segments)
        guard index != activeSegmentIndex else { return }
        activeSegmentIndex = index
    }

    /// Index of the segment that contains `time`, using segment boundaries from transcription.
    private func segmentIndex(for time: Double, in segments: [Segment]) -> Int {
        if let match = segments.firstIndex(where: { time >= $0.start && time < $0.end }) {
            return match
        }
        if time < segments[0].start {
            return 0
        }
        if let lastIndex = segments.indices.last, time >= segments[lastIndex].start {
            return lastIndex
        }
        return segments.lastIndex(where: { time >= $0.start }) ?? 0
    }

    private func formatTimestamp(_ seconds: Double) -> String {
        let total = Int(seconds.rounded(.down))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    CaptionsEditTextSheetView()
}

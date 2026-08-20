//
//  Notification+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/02/2025.
//

import Foundation

extension Notification.Name {
    static let OverlayLabelViewsUpdated = Notification.Name("overlayLabelViewsUpdated")
    static let SelectedLabelViewChanged = Notification.Name("selected LabelView Changed")
    static let CurrentSpidAssetDidChange = Notification.Name("currentSpidAssetDidChange")
    static let ProjectHistoryDiffDidChange = Notification.Name("projectHistoryDiffDidChange")
    static let BackgroundAudioTrackUpdated = Notification.Name("backgroundAudioTrackUpdated")
    /// Posted while the video plays with the current playback time (seconds).
    static let captionsPlaybackTimeDidChange = Notification.Name("captionsPlaybackTimeDidChange")
}

enum CaptionsPlaybackTimeNotification {
    static let currentTimeKey = "currentTime"
}

enum ProjectHistoryDiffNotification {
    static let diffKey = "projectHistoryDiff"
}

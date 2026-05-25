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
    static let VideoSelectionChanged = Notification.Name("video selection changed")
    /// Posted while the video plays with the current playback time (seconds).
    static let captionsPlaybackTimeDidChange = Notification.Name("captionsPlaybackTimeDidChange")
}

enum CaptionsPlaybackTimeNotification {
    static let currentTimeKey = "currentTime"
}

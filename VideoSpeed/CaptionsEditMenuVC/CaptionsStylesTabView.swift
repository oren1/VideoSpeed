//
//  CaptionsStylesTabView.swift
//  VideoSpeed
//
//  Created by Codex on 21/04/2026.
//

import SwiftUI
import UIKit

struct CaptionsStylesTabView: View {
    @ObservedObject private var captionsStyle: CaptionsStyle

    private let fontSizeRange: ClosedRange<CGFloat> = 12...96
    private let borderWidthRange: ClosedRange<CGFloat> = 0...20

    init() {
        _captionsStyle = ObservedObject(wrappedValue: CaptionStyleGenerator.captionsStyle)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        CaptionsStyleUIColorPickerScreen(title: "Text color", color: $captionsStyle.textColor)
                    } label: {
                        colorRow(title: "Text color", uiColor: captionsStyle.textColor)
                    }

                    NavigationLink {
                        CaptionsStyleUIColorPickerScreen(title: "Border color", color: $captionsStyle.borderColor)
                    } label: {
                        colorRow(title: "Border color", uiColor: captionsStyle.borderColor)
                    }

                    NavigationLink {
                        CaptionsStyleHighlightColorScreen(captionsStyle: captionsStyle)
                    } label: {
                        highlightColorRow
                    }

                    Button("Clear highlight color") {
                        captionsStyle.highlightColor = nil
                    }
                    .disabled(captionsStyle.highlightColor == nil)
                } header: {
                    Text("Colors")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font size")
                            Spacer()
                            Text("\(Int(captionsStyle.fontSize)) pt")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $captionsStyle.fontSize, in: fontSizeRange, step: 1)

                        HStack {
                            Text("Border width")
                            Spacer()
                            Text("\(Int(captionsStyle.borderWidth))")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $captionsStyle.borderWidth, in: borderWidthRange, step: 1)
                    }
                } header: {
                    Text("Typography")
                }
            }
            .navigationTitle("Styles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func colorRow(title: String, uiColor: UIColor) -> some View {
        HStack {
            Text(title)
            Spacer()
            Circle()
                .fill(Color(uiColor: uiColor))
                .frame(width: 26, height: 26)
                .overlay {
                    Circle().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                }
        }
    }

    private var highlightColorRow: some View {
        HStack {
            Text("Highlight color")
            Spacer()
            if let c = captionsStyle.highlightColor {
                Circle()
                    .fill(Color(uiColor: c))
                    .frame(width: 26, height: 26)
                    .overlay {
                        Circle().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                    }
            } else {
                Text("None")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Pushed color UI (avoids SwiftUI ColorPicker’s nested sheet over the captions bottom sheet)

private struct CaptionsStyleUIColorPickerScreen: View {
    let title: String
    @Binding var color: UIColor

    var body: some View {
        UIColorPickerRepresentable(color: $color)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CaptionsStyleHighlightColorScreen: View {
    @ObservedObject var captionsStyle: CaptionsStyle

    private var pickerBinding: Binding<UIColor> {
        Binding(
            get: { captionsStyle.highlightColor ?? .systemYellow },
            set: { captionsStyle.highlightColor = $0 }
        )
    }

    var body: some View {
        UIColorPickerRepresentable(color: pickerBinding)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Highlight color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        captionsStyle.highlightColor = nil
                    }
                    .disabled(captionsStyle.highlightColor == nil)
                }
            }
    }
}

private struct UIColorPickerRepresentable: UIViewControllerRepresentable {
    @Binding var color: UIColor

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let vc = UIColorPickerViewController()
        vc.selectedColor = color
        vc.supportsAlpha = true
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: UIColorPickerViewController, context: Context) {
        // Avoid resetting the picker while the user is dragging; sync only when binding changes externally.
        guard vc.selectedColor != color else { return }
        vc.selectedColor = color
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        let parent: UIColorPickerRepresentable

        init(_ parent: UIColorPickerRepresentable) {
            self.parent = parent
        }

        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            parent.color = viewController.selectedColor
        }

        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            parent.color = viewController.selectedColor
        }
    }
}

#Preview {
    CaptionsStylesTabView()
}

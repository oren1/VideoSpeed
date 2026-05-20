//
//  CaptionsSectionView.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 12/08/2025.
//

import SwiftUI

class CaptionItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    var startTime: Double
    var endTime: Double
    var text: String

    init(startTime: Double, endTime: Double, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
    
    // MARK: - Hashable
    static func == (lhs: CaptionItem, rhs: CaptionItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
           hasher.combine(id)
    }

    static func generatePreviewCaptions() -> [CaptionItem] {
           var items: [CaptionItem] = []
           var currentTime: Double = 0
           for i in 1...10 {
               let duration = Double.random(in: 0.5..<5)
               let start = currentTime
               let end = start + duration
               items.append(CaptionItem(startTime: start, endTime: end, text: "Caption \(i)"))
               currentTime = end
           }
           return items
    }
}

struct CaptionsSectionView: View {
    @ObservedObject var viewModel: CaptionsViewModel
    var editStyleTapped: (() -> Void)?
    var generateCaptionsTapped: (() -> Void)?

    @State private var isEditTextSheetPresented = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                sectionActionButton(title: "Edit Text") {
                    isEditTextSheetPresented = true
                }
                sectionActionButton(title: "Edit Style") {
                    editStyleTapped?()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                generateCaptionsTapped?()
            } label: {
                Text("Select Language")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(uiColor: .systemBlue))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .sheet(isPresented: $isEditTextSheetPresented) {
            CaptionsEditTextSheetView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }

    private func sectionActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let captionItems = CaptionItem.generatePreviewCaptions()
    let viewModel = CaptionsViewModel(captions: captionItems, lastEditedCaption: captionItems.first!)
        
    CaptionsSectionView(viewModel: viewModel)
}

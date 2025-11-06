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
    @State private var scrollTarget: UUID?

    var body: some View {
        ZStack {
            VStack {

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.captions, id: \.self) { item in
                                VStack {
                                    Text("\(item.text)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Image(systemName: "pencil.and.ellipsis.rectangle")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(.blue)
                                }
                                .frame(width: 100, height: 60)
                                .background(.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(1), lineWidth: 1)
                                )
                                .cornerRadius(6)                                .cornerRadius(6)
                                .id(item.id) // 👈 Give each item an id for scrollTo
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 150)
                    .onChange(of: scrollTarget) { oldValue, newValue in
                        // ✅ New two-parameter closure version
                        if let targetID = newValue {
                            withAnimation {
                                proxy.scrollTo(targetID, anchor: .center)
                            }
                        }
                    }
                    .onAppear {
                                    // Scroll to the 5th caption after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            scrollTarget = viewModel.captions[4].id
                        }
                    }
                             
                }
                
                HStack {
                           Spacer()
                           
                           Button(action: {
                               editStyleTapped?()
                           }) {
                               Image(systemName: "long.text.page.and.pencil")
                                   .resizable()
                                   .scaledToFit()
                                   .frame(width: 35, height: 35)
                                   .foregroundColor(.white)
                           }
                           Spacer()
                       }
                       .frame(height: 50)
                       .background(Color.clear)
                       .cornerRadius(12)
                       .padding(.horizontal)
            }

        }.background(Color.black)
    }
}


#Preview {
    let captionItems = CaptionItem.generatePreviewCaptions()
    let viewModel = CaptionsViewModel(captions: captionItems, lastEditedCaption: captionItems.first!)
    CaptionsSectionView(viewModel: viewModel)
}



//                List(viewModel.captions) { item in
//                    HStack {
//                        Text(String(format: "%.2f - %.2f", item.startTime, item.endTime))
//                            .font(.subheadline)
//                            .foregroundColor(Color.gray)
//                            .frame(width: 120, alignment: .leading)
//                        Text(item.text)
//                            .font(.body)
//                            .foregroundColor(Color.white)
//
//                        Spacer()
//
//                        Button(action: {
//                            print("Edit tapped for: \(item.text)")
//                        }) {
//                            Image(systemName: "pencil.and.ellipsis.rectangle")
//                                .foregroundColor(.white)
//                                .imageScale(.medium)
//                        }
//    //                    .buttonStyle(BorderlessButtonStyle())
//                        // prevent row selection override
//                        .padding(.trailing, 16)
//                    }
//                    .padding(.vertical, 4)
//                    .listRowBackground(Color.clear)
//
//                }
//                .listStyle(PlainListStyle())
//                .background(Color.black)

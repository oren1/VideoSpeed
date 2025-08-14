//
//  CaptionsSectionView.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 12/08/2025.
//

import SwiftUI

import SwiftUI

class CaptionItem: Identifiable {
    let id = UUID()
    var startTime: Double
    var endTime: Double
    var text: String

    init(startTime: Double, endTime: Double, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
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

    var body: some View {
        ZStack {
            Color.red
            List(viewModel.captions) { item in
                HStack {
                    Text(String(format: "%.2f - %.2f", item.startTime, item.endTime))
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .frame(width: 120, alignment: .leading)
                    Text(item.text)
                        .font(.body)
                        .foregroundColor(Color.white)
                   
                    Spacer()
                    
                    Button(action: {
                        print("Edit tapped for: \(item.text)")
                    }) {
                        Image(systemName: "pencil.and.ellipsis.rectangle")
                            .foregroundColor(.white)
                            .imageScale(.medium)
                    }
//                    .buttonStyle(BorderlessButtonStyle())
                    // prevent row selection override
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                
               
                
    
            }
            .listStyle(PlainListStyle())
            .background(Color.black)
        }.background(Color.black)
    }
}


#Preview {
    let captionItems = CaptionItem.generatePreviewCaptions()
    let viewModel = CaptionsViewModel(captions: captionItems, lastEditedCaption: captionItems.first!)
    CaptionsSectionView(viewModel: viewModel)
}

//
//  CaptionsSettingsSelectionView.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 15/08/2025.
//

import SwiftUI




import SwiftUI
import Speech

struct CaptionsSettingsSelectionView: View {
    
    var generatedCaptions: ((LanguageItem) -> Void)?
    @State private var searchText = ""
    @State private var languages = UserDataManager.main.languageItems
    
    
    var filteredLanguages: [LanguageItem] {
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter {
                $0.localizedString.localizedCaseInsensitiveContains(searchText) ||
                $0.identifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Custom search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                                Text("Search language")
                                    .foregroundColor(.gray) // <-- Placeholder color
                            }
                            TextField("", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                    }
            
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding([.bottom], 12)
                
                
                List {
                    ForEach(filteredLanguages) { item in
                        HStack {
                            Text("\(item.localizedString)")
                                .foregroundStyle(Color.white)
                            Spacer()
                            if item.isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectLanguage(item)
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    
                }
                .listStyle(PlainListStyle())
                .background(Color.black)
              
                // Bottom button
                Button(action: {
                    if let selectedLanguageItem = languages.first(where: { $0.isSelected }) {
                        generatedCaptions?(selectedLanguageItem)
                    }
                }) {
                    Text("Generate Captions")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.black)
            }
            .background(Color.black)
        }
    }
    
    
    private func selectLanguage(_ selectedItem: LanguageItem) {
        // Update selection
        for i in languages.indices {
            languages[i].isSelected = (languages[i].identifier == selectedItem.identifier)
        }
    }
}


#Preview {
    CaptionsSettingsSelectionView()
}

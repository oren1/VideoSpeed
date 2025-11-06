//
//  CaptionsSettingsSelectionView.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 15/08/2025.
//

import SwiftUI
import Speech

struct CaptionsSettingsSelectionView: View {
    
    var generateCaptions: ((LanguageItem) async throws -> Void)?
    var onClose: (() -> Void)?
    @State private var searchText = ""
    @State private var languages = UserDataManager.main.languageItems
    @State private var generatingCaptions: Bool = false
    @State private var selectedLanguageItem = UserDataManager.main.languageItems.first!
    
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
            if generatingCaptions {
                ZStack {
                    Color.black.opacity(0.75)
                    loadingMediaView()
                }
                .ignoresSafeArea(.all)
            }
            else {
                VStack(spacing: 0) {
                    // Top-left Close button
                    HStack {
                        Button(action: {
                              onClose?()
                        }) {
                            Image(systemName: "x.circle")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                        }
                        .padding([.leading, .bottom], 25)
                      Spacer()
                    }
                              
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
                                if item == selectedLanguageItem {
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
//                        if let selectedLanguageItem {
                            Task {
                                generatingCaptions = true
                                do {
                                    try await generateCaptions?(selectedLanguageItem)
                                } catch  {
                                    print("transcription error: \(error)")
                                }
                                
                                generatingCaptions = false
                                onClose?()
                            }
//                        }
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
       
    }
    
    
    private func selectLanguage(_ selectedItem: LanguageItem) {
        selectedLanguageItem = selectedItem
    }
    
    func loadingMediaView() -> some View {
        let loadingMediaViewModel = LoadingMediaViewModel()
        loadingMediaViewModel.showProgress = false
        loadingMediaViewModel.title = "Creating Captions..."
        return LoadingMediaView(loadingMediaViewModel: loadingMediaViewModel)
    }
}


#Preview {
    CaptionsSettingsSelectionView()
}

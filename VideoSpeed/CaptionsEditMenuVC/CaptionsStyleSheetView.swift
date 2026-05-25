//
//  CaptionsStyleSheetView.swift
//  VideoSpeed
//
//  Created by Codex on 20/04/2026.
//

import SwiftUI

struct CaptionsStyleSheetView: View {
    private enum TopMenuTab: String, CaseIterable, Identifiable {
        case templates = "Templates"
        case fonts = "Fonts"
        case styles = "Styles"

        var id: Self { self }
    }

    @State private var selectedTab: TopMenuTab = .templates
    @Namespace private var selectionUnderlineNamespace

    var body: some View {
        VStack(spacing: 0) {
            topMenu

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 20)
        .background {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
        }
    }

    private var topMenu: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                ForEach(TopMenuTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Text(tab.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedTab == tab ? .primary : .secondary)

                            ZStack {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.primary)
                                        .frame(height: 2)
                                        .matchedGeometryEffect(id: "topMenuUnderline", in: selectionUnderlineNamespace)
                                } else {
                                    Capsule()
                                        .fill(Color.clear)
                                        .frame(height: 2)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .templates:
            CaptionsTemplatesTabView { type in
                CaptionStyleGenerator.captionsStyle.captionType = type
            }
        case .fonts:
            CaptionsFontsTabView()
        case .styles:
            CaptionsStylesTabView()
        }
    }
}

#Preview {
    CaptionsStyleSheetView()
}

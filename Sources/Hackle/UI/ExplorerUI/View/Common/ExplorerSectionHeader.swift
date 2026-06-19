//
//  ExplorerSectionHeader.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/19/26.
//

import SwiftUI

struct ExplorerSectionHeader<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.explorerSecondaryText)
            Spacer()
            content
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
        .background(Color.white)
    }
}

extension ExplorerSectionHeader where Content == EmptyView {
    init(_ title: String) {
        self.init(title) {
            EmptyView()
        }
    }
}

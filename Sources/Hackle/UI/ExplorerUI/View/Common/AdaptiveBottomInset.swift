//
//  AdaptiveBottomInset.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/19/26.
//

import SwiftUI

extension View {
    @ViewBuilder func adaptiveBottomInset<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 15.0, *) {
            self.safeAreaInset(edge: .bottom, spacing: 0) {
                content()
            }
        } else {
            ZStack(alignment: .bottom) {
                self.padding(.bottom, 60)
                content()
            }
        }
    }
}

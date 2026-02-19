//
//  SimpleStoreStackRow.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public struct SimpleStoreStackRow<Content: View>: View {
    private let showsSeparator: Bool
    private let content: Content

    public init(
        showsSeparator: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.showsSeparator = showsSeparator
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            if showsSeparator {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

#if DEBUG
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
#Preview {
    ScrollView {
        LazyVStack(spacing: 0) {
            SimpleStoreStackRow {
                Text("First Row")
            }
            SimpleStoreStackRow {
                Text("Second Row")
            }
            SimpleStoreStackRow(showsSeparator: false) {
                Text("Last Row")
            }
        }
    }
}
#endif

#endif

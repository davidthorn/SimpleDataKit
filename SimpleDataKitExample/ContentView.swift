//
//  ContentView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StartHereView()
                .tabItem {
                    Label("Start", systemImage: "sparkles")
                }

            ExamplesHomeView()
                .tabItem {
                    Label("Examples", systemImage: "book.pages")
                }
        }
    }
}

#Preview {
    ContentView()
}

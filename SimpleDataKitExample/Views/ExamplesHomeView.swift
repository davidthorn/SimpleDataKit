//
//  ExamplesHomeView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI

struct ExamplesHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Core") {
                    NavigationLink("Core Store API", value: ExampleRoute.coreStore)
                    NavigationLink("Global Functions API", value: ExampleRoute.globalFunctions)
                    NavigationLink("Persistable API", value: ExampleRoute.persistable)
                }

                Section("UI") {
                    NavigationLink("SimpleStoreList", value: ExampleRoute.simpleStoreList)
                    NavigationLink("SimpleStoreStack", value: ExampleRoute.simpleStoreStack)
                }

                Section("Advanced") {
                    NavigationLink("Manual Store Wiring", value: ExampleRoute.manualWiring)
                }
            }
            .navigationTitle("Examples")
            .navigationDestination(for: ExampleRoute.self) { route in
                switch route {
                case .coreStore:
                    CoreStoreDemoView()
                case .globalFunctions:
                    GlobalFunctionsDemoView()
                case .persistable:
                    PersistableDemoView()
                case .simpleStoreList:
                    ListDemoView()
                case .simpleStoreStack:
                    StackDemoView()
                case .manualWiring:
                    ManualWiringDemoView()
                }
            }
        }
    }
}

#Preview {
    ExamplesHomeView()
}

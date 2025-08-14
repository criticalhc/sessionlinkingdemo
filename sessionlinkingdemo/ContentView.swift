//
//  ContentView.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeView()
    }

}

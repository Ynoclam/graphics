//
//  graphycsApp.swift
//  graphycs
//
//  Created by Максим Кобрянов on 6.10.2025.
//

import SwiftUI

@main
struct graphycsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(selectionDate: .constant(Date()))
        }
    }
}

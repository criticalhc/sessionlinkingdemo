//
//  Untitled.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 18/08/2025.
//

import SwiftUI

struct CustomValueKey: EnvironmentKey {
    static let defaultValue: AppViewFactory = AppViewFactory()
}

extension EnvironmentValues {
    var customValue: AppViewFactory {
        get { self[CustomValueKey.self] }
        set { self[CustomValueKey.self] = newValue }
    }
}


var globalWebsocketManager = WebSocketManager()

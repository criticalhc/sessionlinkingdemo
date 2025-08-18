//
//  HomeView.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//

import SwiftUI


struct HomeView:  View {
    @StateObject var cameraModel = QRScannerModel()
    
    
    var body: some View {
        VStack {
            
            if let code = cameraModel.scannedCode {
                Text(code)
            } else {
                CameraPreview(session: cameraModel.session).onAppear
                {
                    cameraModel.checkPermissions()
                }
                DrawingCanvasView(viewModel: DrawingCanvasViewModel())
            }
            
            
        }
        
        
    }
}

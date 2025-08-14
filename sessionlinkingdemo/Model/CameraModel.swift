//
//  CameraModel.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//

import AVKit

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupSession() }
            }
        default:
            print("Camera permission denied.")
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to get camera device.")
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        
        session.commitConfiguration()
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    // Capture Delegate
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let data = photo.fileDataRepresentation(),
           let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            print("Photo saved to library.")
        }
    }
}

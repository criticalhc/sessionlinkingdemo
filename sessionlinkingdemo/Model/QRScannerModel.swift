//
//  QRScannerModel.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//


import SwiftUI
import AVFoundation

class QRScannerModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var session = AVCaptureSession()
    @Published var scannedCode: String? // Holds the detected QR code value
    
    private let metadataOutput = AVCaptureVideoDataOutput()
    
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
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    // MARK: - QR Code Detection
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           object.type == .qr,
           let value = object.stringValue {
            scannedCode = value
            print("QR Code detected: \(value)")
            
            // Optional: Stop scanning after first detection
            session.stopRunning()
        }
    }
    
    func detectTags(in grayscalePixels: UnsafeMutablePointer<UInt8>, width: Int32, height: Int32) {
        // Create an image_u8_t from raw grayscale data
        var im = image_u8_t(width: width, height: height, stride: width, buf: grayscalePixels)

        // Create detector
        let tf = tag36h11_create()
        let td = apriltag_detector_create()
        apriltag_detector_add_family(td, tf)

        // Detect
        let detections = apriltag_detector_detect(td, &im)

        // Loop through results
        for i in 0..<Int(detections!.pointee.size) {
            print(detections?.pointee.data)
        }
        
        // Cleanup
        apriltag_detections_destroy(detections)
        apriltag_detector_destroy(td)
        tag36h11_destroy(tf)
    }
    
    
    func detectTagsFromCGImage(_ cgImage: CGImage) {
        let width = cgImage.width
        let height = cgImage.height
        
        // Allocate a buffer for grayscale pixels
        let bytesPerPixel = 1
        let bytesPerRow = width * bytesPerPixel
        let bufferSize = height * bytesPerRow
        let grayscalePixels = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        
        defer {
            grayscalePixels.deallocate()
        }
        
        // Create a grayscale color space
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        // Create a CGContext with our buffer
        guard let context = CGContext(
            data: grayscalePixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            print("Failed to create CGContext")
            return
        }
        
        // Draw the CGImage into the grayscale context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        // Now grayscalePixels points to width*height bytes of grayscale data
        detectTags(in: grayscalePixels, width: Int32(width), height: Int32(height))
    }

}

extension QRScannerModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Convert to a format your AprilTag library supports
        // Example: using CoreImage to get CGImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            detectTagsFromCGImage(cgImage)
        }
    }
}

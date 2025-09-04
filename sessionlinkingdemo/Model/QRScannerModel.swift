//
//  QRScannerModel.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//


import SwiftUI
import AVFoundation
import Vision
import CoreGraphics
import AprilTagWrapper


class QRScannerModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var session = AVCaptureSession()
    @Published var scannedCode: String? // Holds the detected QR code value
    @Published var stopScanning = false
    
    private let videoCaptureOutput = AVCaptureVideoDataOutput()
    private let metadataOutPut = AVCaptureMetadataOutput()
    
    private var aprilTags: Set<AprilTagDTO> = Set()
    private var qrCodeDto: QRCodeDTO? = nil
    
    private var aprilTagDetector: AprilTagDetector = AprilTagDetector()
    
    
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
        
        try! AVCaptureDevice.default(for: .video)?.lockForConfiguration()

        
        AVCaptureDevice.default(for: .video)?.activeVideoMinFrameDuration = CMTime(seconds: 1.0 / 5, preferredTimescale: 1000)
        AVCaptureDevice.default(for: .video)?.activeVideoMaxFrameDuration = CMTime(seconds: 1.0 / 5, preferredTimescale: 1000)

        
        if session.canAddInput(input) { session.addInput(input) }
        
        if session.canAddOutput(videoCaptureOutput) {
            session.addOutput(videoCaptureOutput)
            
            videoCaptureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        }
        
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func detectTags(in grayscalePixels: UnsafeMutablePointer<UInt8>, width: Int32, height: Int32) {
        var im = image_u8_t(width: width, height: height, stride: width, buf: grayscalePixels)

        aprilTagDetector.addFamily(AprilTagFamily(name: "tag36h11")!)

        let detections = aprilTagDetector.detect(image: &im)
        
        
        // Loop through resultsx
        for detection in detections {
            print(detection)
                if aprilTags.count < 5 {
            let tag = AprilTagDTO(id: String(detection.id), centre: [detection.center.0, detection.center.1] , corners: detection.corners.map { [$0.0, $0.1]} )
                    aprilTags.insert(tag)
                } else {
                    stopScanning = true
                    Task {
                        let data = await sendDataToServer(qrCode: qrCodeDto!, aprilTags: Array(aprilTags), sessionId: qrCodeDto!.session_id)
                        print(String(data: data, encoding: .utf8))
                        globalWebsocketManager.connect(url: URL(string: "wss://stronghold-test.onrender.com/ws/\(qrCodeDto!.session_id)/\(UUID().uuidString)")!)
                        session.stopRunning()
                    }
                }
        }
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
    
    

    func readQRCode(from cgImage: CGImage) {
        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                print("Error detecting barcodes: \(error)")
                return
            }
            
            for case let observation as VNBarcodeObservation in request.results ?? [] {
                if let payload = observation.payloadStringValue {
                    self.qrCodeDto = self.processQRCodeData(payload)
                    print("QR Code found: \(payload)")
                }
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision error: \(error)")
        }
    }
    
    func processQRCodeData(_ codeData: String) -> QRCodeDTO {
        var qrData: String

        // If it starts with "https://", try to extract the value after "data="
        if codeData.hasPrefix("https://") {
            if let range = codeData.range(of: "data=") {
                qrData = String(codeData[range.upperBound...])
            } else {
                qrData = codeData // fallback if "data=" not found
            }
        } else {
            qrData = codeData
        }
        print("✅ QR Code Detected: \(qrData)")

        // Decode URL-encoded data
        if let decoded = qrData.removingPercentEncoding {
            qrData = decoded
        }
        print("✅ QR Code Detected: \(qrData)")

        // If it starts and ends with quotes, strip them
        if qrData.hasPrefix("\"") && qrData.hasSuffix("\"") {
            qrData = String(qrData.dropFirst().dropLast())
        }
        print("✅ QR Code Detected: \(qrData)")

        // Replace escaped quotes (\") with real quotes (")
        qrData = qrData.replacingOccurrences(of: "\\\"", with: "\"")
        print("✅ QR Code Detected: \(qrData)")

        return try! JSONDecoder().decode(QRCodeDTO.self, from: qrData.data(using: .utf8)!)
    }
    
    func sendDataToServer(qrCode: QRCodeDTO, aprilTags: [AprilTagDTO], sessionId: String) async -> Data {
        var request = URLRequest(url: URL(string: "https://stronghold-test.onrender.com/send-message/\(sessionId)")!)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(PayloadDTO(qrData: qrCode, aprilTags: aprilTags))
        return try! await URLSession.shared.data(for: request).0
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
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent), !stopScanning {
            readQRCode(from: cgImage)
            detectTagsFromCGImage(cgImage)
        }
    }
}

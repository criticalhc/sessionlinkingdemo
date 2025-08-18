//
//  PayloadDTO.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 18/08/2025.
//


struct PayloadDTO: Codable {
    var qrData: QRCodeDTO
    var aprilTags: [AprilTagDTO]
}

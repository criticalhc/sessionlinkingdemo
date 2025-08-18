//
//  AprilTagDTO.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 15/08/2025.
//


struct AprilTagDTO: Codable, Hashable, Equatable {
    var id: String
    var centre: [Double]
    var corners: [[Double]]

    static func == (lhs: AprilTagDTO, rhs: AprilTagDTO) -> Bool {
        return lhs.centre == rhs.centre && lhs.corners == rhs.corners
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(centre)
        hasher.combine(corners)
    }
}

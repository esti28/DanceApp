//
//  DetectReferencePose.swift
//  DanceApp
//
//  Created by Saarthak Trivedi on 1/8/25.
//

import Foundation
import Vision
import AVFoundation

// struct to store pose with timestamp
struct TimestampedPose: Codable {
    let timestampSeconds: Double
    let pose: VNHumanBodyPose3DObservation
    
    //encoding for a pose observation
    private enum CodingKeys: String, CodingKey {
        case timestampSeconds
        case pose
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestampSeconds, forKey: .timestampSeconds)
        let poseData = try NSKeyedArchiver.archivedData(withRootObject: pose, requiringSecureCoding: true)
        try container.encode(poseData, forKey: .pose)
    }
    
    init(timestamp: CMTime, pose: VNHumanBodyPose3DObservation) {
        self.timestampSeconds = CMTimeGetSeconds(timestamp)
        self.pose = pose
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestampSeconds = try container.decode(Double.self, forKey: .timestampSeconds)
        let poseData = try container.decode(Data.self, forKey: .pose)
        guard let pose = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(poseData) as? VNHumanBodyPose3DObservation else {
            throw DecodingError.dataCorruptedError(forKey: .pose, in: container, debugDescription: "Failed to decode pose")
        }
        self.pose = pose
    }
}

class PoseDetector {
    private var videoAsset: AVAsset?
    private var poseDetectionRequest: VNDetectHumanBodyPose3DRequest?
    
    init() {
        self.poseDetectionRequest = VNDetectHumanBodyPose3DRequest()
    }
    
    func detectPoses(fromVideoAt url: URL) async throws -> [TimestampedPose] {
        let asset = AVAsset(url: url)
        self.videoAsset = asset
        
        let reader = try AVAssetReader(asset: asset)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "PoseDetector", code: 1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }
        
        let outputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        reader.add(readerOutput)
        
        reader.startReading()
        
        var timestampedPoses: [TimestampedPose] = []
        
        // Process video frame-by-frame
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up)
                try handler.perform([poseDetectionRequest!])
                
                if let results = poseDetectionRequest?.results,
                   let observation = results.first as? VNHumanBodyPose3DObservation {
                    let timestampedPose = TimestampedPose(timestamp: timestamp, pose: observation)
                    timestampedPoses.append(timestampedPose)
                }
            }
        }
        
        return timestampedPoses
    }
    
    func savePoseObservations(_ observations: [TimestampedPose], to url: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(observations)
        try data.write(to: url)
    }
    
    func loadPoseObservations(from url: URL) throws -> [TimestampedPose] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([TimestampedPose].self, from: data)
    }
}

@main
struct DetectPoseScript {
    static func main() async {
            // Get command line arguments
        let arguments = CommandLine.arguments
        
        guard arguments.count == 3 else {
            print("Usage: ProcessVideo <input_video_path> <output_file_path>")
            return
        }
        
        let inputPath = arguments[1]
        let outputPath = arguments[2]
        
        let detector = PoseDetector()
        
        do {
            print("Processing video...")
            let observations = try await detector.detectPoses(fromVideoAt: URL(fileURLWithPath: inputPath))
            print("Found \(observations.count) poses")
            
            try detector.savePoseObservations(observations, to: URL(fileURLWithPath: outputPath))
            print("Successfully saved poses to \(outputPath)")
        } catch {
            print("Error: \(error)")
        }
    }
}

//@main
//struct DetectPoseScript {
//    static func main() {
//        Task {
//            await execute()
//        }
//    }
//
//    static func execute() async {
//        let arguments = CommandLine.arguments
//        
//        guard arguments.count == 3 else {
//            print("Usage: ProcessVideo <input_video_path> <output_file_path>")
//            return
//        }
//        
//        let inputPath = arguments[1]
//        let outputPath = arguments[2]
//        
//        let detector = PoseDetector()
//        
//        do {
//            print("Processing video...")
//            let observations = try await detector.detectPoses(fromVideoAt: URL(fileURLWithPath: inputPath))
//            print("Found \(observations.count) poses")
//            
//            try detector.savePoseObservations(observations, to: URL(fileURLWithPath: outputPath))
//            print("Successfully saved poses to \(outputPath)")
//        } catch {
//            print("Error: \(error)")
//        }
//    }
//}

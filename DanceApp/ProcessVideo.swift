//
//  ProcessVideo.swift
//  DanceApp
//
//  Created by Saarthak Trivedi on 1/7/25.
//

import Vision
import AVFoundation

class VideoProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        self.detectPose(pixelBuffer)
        
    }
    
    func setUpCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video, position: .unspecified)
        guard
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoInput)
            else {return nil}
        captureSession.addInput(videoInput)
        let videoOutput = AVCaptureVideoDataOutput()
        guard captureSession.canAddOutput(videoOutput) else {return nil}
        captureSession.sessionPreset = .hd1280x720
        let videoQueue = DispatchQueue(label: "videoQueue")
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()
        return captureSession
    }
    
    func detectPose(_ pixelBuffer: CVPixelBuffer) {
        let poseRequest = VNDetectHumanBodyPose3DRequest { [weak self] request,
            error in
            guard let self else {return}
            guard let observations = request.results as? [VNHumanBodyPose3DObservation], !observations.isEmpty else {return}
            self.processPoseObservations(observations)
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        
        do {
            try requestHandler.perform([poseRequest])
        } catch {
            print("Failed to perform pose detection request: \(error)")
        }
    }
    
    func processPoseObservations(_ observations: [VNHumanBodyPose3DObservation]) {
        return
    }
}

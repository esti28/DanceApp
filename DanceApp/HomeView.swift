//
//  HomeView.swift
//  DanceApp
//
//  Created by Saarthak Trivedi on 1/8/25.
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    var body: some View {
        let videoProcessor = VideoProcessor()
        let captureSession = videoProcessor.setUpCaptureSession()
        Text("Hello World!")
        Button("Start recording") {
            if captureSession != nil {
                captureSession!.startRunning()
            } else {
                print("Error: Couldn't set up capture session")
            }
        }
    }
}

#Preview {
    HomeView()
}

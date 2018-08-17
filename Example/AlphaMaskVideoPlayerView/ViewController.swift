//
//  ViewController.swift
//  AlphaMaskVideoPlayerView
//
//  Created by 🦊Tomoya Hirano on 11/16/2017.
//  Copyright (c) 2017 🦊Tomoya Hirano. All rights reserved.
//

import UIKit
import AlphaMaskVideoPlayerView
import AVFoundation

final class ViewController: UIViewController, AlphaMaskVideoPlayerDelegate {
  let player = AlphaMaskVideoPlayer(mainVideoUrl: Bundle.main.url(forResource: "main", withExtension: "mp4")!,
                                    alphaVideoUrl: Bundle.main.url(forResource: "alpha", withExtension: "mp4")!,
                                    fps: 30)
  @IBOutlet private weak var playerView: AlphaMaskVideoPlayerView!
  
  private let camera = AVCaptureDevice.default(for: AVMediaType.video)
  private lazy var input: AVCaptureDeviceInput = try! .init(device: camera!)
  private let session = AVCaptureSession()
  private lazy var preview = AVCaptureVideoPreviewLayer(session: self.session)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    preview.frame = view.bounds
    view.layer.insertSublayer(preview, at: 0)
    session.addInput(input)
    session.startRunning()
    
    playerView.setPlayer(player)
    playerView.contentMode = .scaleAspectFill
    playerView.contentScaleFactor = UIScreen.main.scale
    player.delegate = self
    try! player.play()
  }
  
  func playerDidFinishPlaying(_ player: AlphaMaskVideoPlayer) {
    print("finish")
  }
  
  func playerDidCancelPlaying(_ player: AlphaMaskVideoPlayer) {
    print("cancel")
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    do {
      player.cancel()
      try player.play()
    } catch {
      print("not able to play.")
    }
  }
}


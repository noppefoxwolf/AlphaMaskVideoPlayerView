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
                                    alphaVideoUrl: Bundle.main.url(forResource: "main_alpha", withExtension: "mp4")!)
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
    player.delegate = self
    try! player.play()
  }
  
  func playerDidFinishPlaying(_ player: AlphaMaskVideoPlayer) {
    player.cancel()
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    try! player.play()
  }
}


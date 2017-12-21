//
//  AlphaMaskVideoPlayer.swift
//  AlphaMaskVideoPlayerView
//
//  Created by Tomoya Hirano on 2017/11/16.
//

import AVFoundation

internal protocol AlphaMaskVideoPlayerUpdateDelegate: class {
  func didOutputFrame(_ image: CIImage?)
  func didReceiveError(_ error: Error?)
}

public protocol AlphaMaskVideoPlayerDelegate: class {
  
  func playerDidFinishPlaying(_ player: AlphaMaskVideoPlayer)
  func playerDidCancelPlaying(_ player: AlphaMaskVideoPlayer)
}

open class AlphaMaskVideoPlayer: NSObject {
  private let outputSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA]
  private let mainAsset: AVURLAsset
  private let alphaAsset: AVURLAsset
  private var mainAssetReader: AVAssetReader!
  private var alphaAssetReader: AVAssetReader!
  private var mainOutput: AVAssetReaderTrackOutput!
  private var alphaOutput: AVAssetReaderTrackOutput!
  private let maskFilter = CIFilter(name: "CIBlendWithMask")
  private static let queue = DispatchQueue(label: "com.noppe.AlphaMaskVideoPlayer.video")
  public weak var delegate: AlphaMaskVideoPlayerDelegate? = nil
  internal weak var updateDelegate: AlphaMaskVideoPlayerUpdateDelegate? = nil
  private var previousFrameTime = kCMTimeZero
  private var previousActualFrameTime = CFAbsoluteTimeGetCurrent()
  private lazy var displayLink: CADisplayLink = .init(target: WeakProxy(target: self), selector: #selector(AlphaMaskVideoPlayer.update))
  private var beforeTimeStamp: CFTimeInterval? = nil
  private let timeInterval: CFTimeInterval
  
  public init(mainVideoUrl: URL, alphaVideoUrl: URL, fps: Int) {
    mainAsset = AVURLAsset(url: mainVideoUrl)
    alphaAsset = AVURLAsset(url: alphaVideoUrl)
    timeInterval = 1.0 / CFTimeInterval(fps)
    super.init()
    displayLink.add(to: .main, forMode: .commonModes)
    displayLink.isPaused = true
  }
  
  deinit {
    displayLink.invalidate()
  }
  
  private func reset() throws {
    mainAssetReader = try AVAssetReader(asset: mainAsset)
    alphaAssetReader = try AVAssetReader(asset: alphaAsset)
    mainOutput = AVAssetReaderTrackOutput(track: mainAsset.tracks(withMediaType: AVMediaType.video)[0], outputSettings: outputSettings as [String : Any])
    alphaOutput = AVAssetReaderTrackOutput(track: alphaAsset.tracks(withMediaType: AVMediaType.video)[0], outputSettings: outputSettings as [String : Any])
    if mainAssetReader.canAdd(mainOutput) {
      mainAssetReader.add(mainOutput)
    } else {
      throw AlphaMaskVideoPlayerError()
    }
    if alphaAssetReader.canAdd(alphaOutput) {
      alphaAssetReader.add(alphaOutput)
    } else {
      throw AlphaMaskVideoPlayerError()
    }
    mainOutput.alwaysCopiesSampleData = false
    alphaOutput.alwaysCopiesSampleData = false
    mainAssetReader.startReading()
    alphaAssetReader.startReading()
  }
  
  private func cancelReading() {
    mainAssetReader.cancelReading()
    alphaAssetReader.cancelReading()
  }
  
  public func play() throws {
    try reset()
    displayLink.isPaused = false
  }
  
  public func pause() {
    displayLink.isPaused = true
  }
  
  public func resume() {
    displayLink.isPaused = false
  }
  
  public func cancel() {
    let running = mainAssetReader.status != .completed && mainAssetReader.status != .cancelled
    cancelReading()
    updateDelegate?.didOutputFrame(nil)
    displayLink.isPaused = true
    if running {
      delegate?.playerDidCancelPlaying(self)
    }
  }
  
  private func finish() {
    beforeTimeStamp = nil
    updateDelegate?.didOutputFrame(nil)
    displayLink.isPaused = true
    delegate?.playerDidFinishPlaying(self)
  }
  
  @objc private func update(_ link: CADisplayLink) {
    if let beforeTimeStamp = beforeTimeStamp {
      guard timeInterval <= link.timestamp - beforeTimeStamp else {
        return
      }
    }
    beforeTimeStamp = link.timestamp
    AlphaMaskVideoPlayer.queue.async { [weak self] in
      autoreleasepool(invoking: { [weak self] in
        self?.updateFrame()
      })
    }
  }
  
  private func updateFrame() {
    guard !displayLink.isPaused else { return }
    switch mainAssetReader.status {
    case .completed: finish(); return
    default: break
    }
    guard let (main, alpha) = push() else { return }
    guard let mainCI = image(from: main) else { return }
    guard let alphaCI = image(from: alpha) else { return }
    maskFilter?.setValue(mainCI, forKey: kCIInputImageKey)
    maskFilter?.setValue(alphaCI, forKey: "inputMaskImage")
    updateDelegate?.didOutputFrame(maskFilter?.outputImage)
  }
  
  private func push() -> (CMSampleBuffer?, CMSampleBuffer?)? {
    if let error = mainAssetReader.error {
      updateDelegate?.didReceiveError(error)
      finish()
      return nil
    }
    guard mainAssetReader.status == .reading else { return nil }
    let main = mainOutput.copyNextSampleBuffer()
    if let error = alphaAssetReader.error {
      updateDelegate?.didReceiveError(error)
      finish()
      return nil
    }
    guard alphaAssetReader.status == .reading else { return nil }
    let alpha = alphaOutput.copyNextSampleBuffer()
    return (main, alpha)
  }
  
  private func image(from buffer: CMSampleBuffer?) -> CIImage? {
    guard let buffer = buffer else { return nil }
    guard let pb = CMSampleBufferGetImageBuffer(buffer) else { return nil }
    let ci = CIImage(cvImageBuffer: pb)
    return ci
  }
}



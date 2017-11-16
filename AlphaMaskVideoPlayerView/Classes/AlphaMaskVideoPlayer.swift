//
//  AlphaMaskVideoPlayer.swift
//  AlphaMaskVideoPlayerView
//
//  Created by Tomoya Hirano on 2017/11/16.
//

import UIKit
import AVFoundation

internal protocol AlphaMaskVideoPlayerUpdateDelegate: class {
  func didOutputFrame(_ image: CIImage?)
}

public protocol AlphaMaskVideoPlayerDelegate: class {
  func playerDidFinishPlaying(_ player: AlphaMaskVideoPlayer)
}

open class AlphaMaskVideoPlayer {
  private let outputSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA]
  private let mainAsset: AVURLAsset
  private let alphaAsset: AVURLAsset
  private var mainAssetReader: AVAssetReader!
  private var alphaAssetReader: AVAssetReader!
  private var mainOutput: AVAssetReaderTrackOutput!
  private var alphaOutput: AVAssetReaderTrackOutput!
  private let maskFilter = CIFilter(name: "CIBlendWithMask")
  private let queue = DispatchQueue(label: "com.noppe.video")
  public weak var delegate: AlphaMaskVideoPlayerDelegate? = nil
  internal weak var updateDelegate: AlphaMaskVideoPlayerUpdateDelegate? = nil
  private var previousFrameTime = kCMTimeZero
  private var previousActualFrameTime = CFAbsoluteTimeGetCurrent()
  var playAtActualSpeed: Bool = true
  
  public init(mainVideoUrl: URL, alphaVideoUrl: URL) {
    mainAsset = AVURLAsset(url: mainVideoUrl)
    alphaAsset = AVURLAsset(url: alphaVideoUrl)
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
  }
  
  private func startReading() {
    mainAssetReader.startReading()
    alphaAssetReader.startReading()
  }
  
  private func cancelReading() {
    mainAssetReader.cancelReading()
    alphaAssetReader.cancelReading()
  }
  
  public func play() throws {
    try reset()
    startReading()
    queue.async { [weak self] in
      guard let _self = self else { return }
      while _self.mainAssetReader.status == .reading {
        autoreleasepool(invoking: { [weak self] in
          guard let (main, alpha) = self?.push() else { return }
          guard let mainCI = self?.image(from: main) else { return }
          guard let alphaCI = self?.image(from: alpha) else { return }
          self?.maskFilter?.setValue(mainCI, forKey: kCIInputImageKey)
          self?.maskFilter?.setValue(alphaCI, forKey: "inputMaskImage")
          self?.updateDelegate?.didOutputFrame(self?.maskFilter?.outputImage)
          self?.sleepIfNeeded(with: main)
        })
      }
      _self.delegate?.playerDidFinishPlaying(_self)
    }
  }
  
  public func cancel() {
    cancelReading()
    updateDelegate?.didOutputFrame(nil)
  }
  
  private func sleepIfNeeded(with sampleBuffer: CMSampleBuffer?) {
    guard playAtActualSpeed else { return }
    guard let sampleBuffer = sampleBuffer else { return }
    let currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
    let differenceFromLastFrame = CMTimeSubtract(currentSampleTime, previousFrameTime)
    let currentActualTime = CFAbsoluteTimeGetCurrent()
    
    let frameTimeDifference = CMTimeGetSeconds(differenceFromLastFrame)
    let actualTimeDifference = currentActualTime - previousActualFrameTime
    
    if (frameTimeDifference > actualTimeDifference) {
      usleep(UInt32(round(1000000.0 * (frameTimeDifference - actualTimeDifference))))
    }
    
    previousFrameTime = currentSampleTime
    previousActualFrameTime = CFAbsoluteTimeGetCurrent()
  }
  
  private func push() -> (CMSampleBuffer?, CMSampleBuffer?)? {
    guard mainAssetReader.error == nil else { return nil }
    guard mainAssetReader.status == .reading else { return nil }
    let main = mainOutput.copyNextSampleBuffer()
    guard alphaAssetReader.error == nil else { return nil }
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

//
//  AlphaMaskVideoPlayerView.swift
//  AlphaMaskVideoPlayerView
//
//  Created by Tomoya Hirano on 2017/11/16.
//

import UIKit
import GLKit

open class AlphaMaskVideoPlayerView: GLKView, AlphaMaskVideoPlayerUpdateDelegate {
  private lazy var ciContext: CIContext = .init(eaglContext: context, options: [kCIContextWorkingColorSpace : NSNull()])
  private var image: CIImage? = nil
  private var threadSafeBounds: CGRect = CGRect.zero
  private var threadSafeContentMode: UIViewContentMode = UIViewContentMode.scaleToFill
  private var player: AlphaMaskVideoPlayer? = nil
  
  open override var bounds: CGRect {
    didSet { threadSafeBounds = bounds }
  }
  open override var contentMode: UIViewContentMode {
    didSet { threadSafeContentMode = contentMode }
  }
  
  public override convenience init(frame: CGRect) {
    let eaglContext = EAGLContext(api: .openGLES2)!
    eaglContext.isMultiThreaded = true
    self.init(frame: frame, context: eaglContext)
  }
  
  public override init(frame: CGRect, context: EAGLContext) {
    super.init(frame: frame, context: context)
    enableSetNeedsDisplay = false
    backgroundColor = .clear
    _ = destRect
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    context = EAGLContext(api: .openGLES2)!
    context.isMultiThreaded = true
    enableSetNeedsDisplay = false
    backgroundColor = .clear
    _ = destRect
    contentScaleFactor = 1.0
  }
  
  open override func draw(_ rect: CGRect) {
    glClearColor(0, 0, 0, 0)
    if let image = image {
      ciContext.draw(image, in: destRect(from: image.extent), from: image.extent)
    } else {
      glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }
  }
  
  public func setPlayer(_ player: AlphaMaskVideoPlayer) {
    self.player = player
    self.player?.updateDelegate = self
  }
  
  public func didOutputFrame(_ image: CIImage?) {
    self.image = image
    display()
  }
  
  func didReceiveError(_ error: Error?) {
    self.image = nil
    display()
  }
  open override func layoutSubviews() {
    super.layoutSubviews()
    threadSafeBounds = bounds
    threadSafeContentMode = contentMode
  }
  
  private func destRect(from rect: CGRect) -> CGRect {
    let bounds = threadSafeBounds
    switch threadSafeContentMode {
    case .scaleToFill:
      return bounds
    case .scaleAspectFit:
      let imageRatio = rect.width / rect.height
      let viewRatio = bounds.width / bounds.height
      if viewRatio < imageRatio {
        let ratio = bounds.width / rect.width
        let w = rect.width * ratio
        let h = rect.height * ratio
        let x = (bounds.width - w) / 2.0
        let y = (bounds.height - h) / 2.0
        return CGRect(x: x, y: y, width: w, height: h)
      } else if viewRatio > imageRatio {
        let ratio = bounds.height / rect.height
        let w = rect.width * ratio
        let h = rect.height * ratio
        let x = (bounds.width - w) / 2.0
        let y = (bounds.height - h) / 2.0
        return CGRect(x: x, y: y, width: w, height: h)
      } else {
        return bounds
      }
    case .scaleAspectFill:
      let imageRatio = rect.width / rect.height
      let viewRatio = bounds.width / bounds.height
      if viewRatio < imageRatio {
        let ratio = bounds.height / rect.height
        let w = rect.width * ratio
        let h = rect.height * ratio
        let x = (bounds.width - w) / 2.0
        let y = (bounds.height - h) / 2.0
        return CGRect(x: x, y: y, width: w, height: h)
      } else if viewRatio > imageRatio {
        let ratio = bounds.width / rect.width
        let w = rect.width * ratio
        let h = rect.height * ratio
        let x = (bounds.width - w) / 2.0
        let y = (bounds.height - h) / 2.0
        return CGRect(x: x, y: y, width: w, height: h)
      } else {
        return bounds
      }
    default: return bounds //not supported
    }
  }
}

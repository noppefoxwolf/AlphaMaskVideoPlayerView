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
  }
  
  open override func draw(_ rect: CGRect) {
    glClearColor(0, 0, 0, 0)
    if let image = image {
      ciContext.draw(image, in: destRect, from: image.extent)
    } else {
      glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }
  }
  
  public func setPlayer(_ player: AlphaMaskVideoPlayer) {
    player.updateDelegate = self
  }
  
  public func didOutputFrame(_ image: CIImage?) {
    self.image = image
    display()
  }
  
  private var _destRect: CGRect? = nil
  private var destRect: CGRect {
    guard _destRect == nil else { return _destRect! }
    let scale = UIScreen.main.scale
    _destRect = self.bounds.applying(CGAffineTransform(scaleX: scale, y: scale))
    return _destRect!
  }
}

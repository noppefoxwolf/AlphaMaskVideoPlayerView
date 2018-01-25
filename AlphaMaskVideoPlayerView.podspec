Pod::Spec.new do |s|
  s.name             = 'AlphaMaskVideoPlayerView'
  s.version          = '0.8.0'
  s.summary          = 'A short description of AlphaMaskVideoPlayerView.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/noppefoxwolf/AlphaMaskVideoPlayerView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '🦊Tomoya Hirano' => 'noppelabs@gmail.com' }
  s.source           = { :git => 'https://github.com/noppefoxwolf/AlphaMaskVideoPlayerView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/noppefoxwolf'
  s.ios.deployment_target = '9.0'
  s.source_files = 'AlphaMaskVideoPlayerView/Classes/**/*'
end

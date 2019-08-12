#
# Be sure to run `pod lib lint VideoKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VideoKit'
  s.version          = '0.2.0'
  s.summary          = 'A short description of VideoKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/jonandersen/MusicPickerKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jon Andersen' => 'jon.andersen.se@gmail.com' }
  s.source           = { :git => 'https://github.com/jonandersen/MusicPickerKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/Andersen_Jon'

  s.ios.deployment_target = '11.0'

  s.source_files = 'Sources/**/*'
  
  # s.resource_bundles = {
  #   'VideoKit' => ['VideoKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'AVFoundation'
  s.dependency 'TLPhotoPicker', 'FDWaveformView'
end
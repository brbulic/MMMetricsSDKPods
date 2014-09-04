#
# Be sure to run `pod lib lint MMMetricsSDKPods.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MMMetricsSDKPods"
  s.version          = "0.9.6"
  s.summary          = "Just a cocoapod covering the MetricsSDK"
  s.homepage         = "https://github.com/brbulic/MMMetricsSDKPods"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Bruno Bulic" => "brbulic@gmail.com" }
  s.source           = { :git => "https://github.com/brbulic/MMMetricsSDKPods.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/brbulic'

  s.platform     = :ios, '5.1'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
end

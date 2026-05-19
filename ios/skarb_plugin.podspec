#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint skarb_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'skarb_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'skarb_plugin/Sources/skarb_plugin/**/*'
  s.dependency 'Flutter'
  # Pessimistic pin (~> 0.6.30 == >= 0.6.30, < 0.7) — keep within the 0.6
  # series until a coordinated bump to 0.7. New API surface (stream of
  # cached purchase info + sync getter) requires SkarbSDK >= 0.6.30.
  s.dependency 'SkarbSDK', '~> 0.6.30'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

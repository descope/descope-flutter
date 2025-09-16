#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint descope.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'descope'
  s.version          = '0.0.1'
  s.summary          = 'The Descope Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://descope.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Descope' => 'support@descope.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.7'
end

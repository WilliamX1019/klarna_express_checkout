Pod::Spec.new do |s|
  s.name             = 'klarna_express_checkout'
  s.version          = '0.1.0'
  s.summary          = 'Klarna Express Checkout Flutter Plugin'
  s.description      = 'A Flutter plugin for integrating Klarna Express Checkout on iOS'
  s.homepage         = 'https://github.com/yourusername/klarna_express_checkout'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'KlarnaMobileSDK', '~> 2.8.1'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

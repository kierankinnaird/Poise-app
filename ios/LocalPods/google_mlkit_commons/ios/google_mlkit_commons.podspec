Pod::Spec.new do |s|
  s.name             = 'google_mlkit_commons'
  s.version          = '0.11.1'
  s.summary          = 'Google ML Kit Commons - simulator-compatible local override'
  s.description      = s.summary
  s.homepage         = 'https://github.com/bharat-biradar/Google-Ml-Kit-plugin'
  s.license          = { :type => 'MIT' }
  s.authors          = 'Multiple Authors'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'MLKitVision', '~> 10.0.0'
  s.platform = :ios, '15.5'
  s.ios.deployment_target = '15.5'
  s.static_framework = true
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end

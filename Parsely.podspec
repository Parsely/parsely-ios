Pod::Spec.new do |s|
  s.name           = 'Parsely'
  s.version        = '1.0.2'
  s.license        = 'Apache License, Version 2.0'
  s.summary        = 'Parsely analytics library for iOS.'
  s.homepage       = 'https://www.parsely.com/docs/tools/mobile_sdk.html'
  s.author         = { 'Parsely' => 'https://parsely.com' }

  s.source         = { :git => 'https://github.com/segmentio/parsely-ios.git', :tag => '#{s.version}' }
  s.source_files   = 'ParselyiOS/*.{h,m}', 'ParselyiOS/libs/*.{h,m}'
  s.frameworks     = 'SystemConfiguration', 'Foundation'
end
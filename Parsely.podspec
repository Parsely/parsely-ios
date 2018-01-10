Pod::Spec.new do |s|
  s.name           = 'Parsely'
  s.version        = '2.3'
  s.license        = 'Apache License, Version 2.0'
  s.summary        = 'Parsely analytics library for iOS.'
  s.homepage       = 'https://www.parsely.com/docs/tools/mobile_sdk.html'
  s.author         = { 'Parsely' => 'https://parsely.com' }

  s.source         = { :git => 'https://github.com/Parsely/parsely-ios.git', :tag => '2.3' }
  s.source_files   = 'ParselyiOS/*.{h,m}', 'ParselyiOS/libs/*.{h,m}'
  s.frameworks     = 'SystemConfiguration', 'Foundation'

  s.platforms      = { :ios => '7.0' }
end

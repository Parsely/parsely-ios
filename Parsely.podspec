Pod::Spec.new do |s|
  s.name           = 'Parsely'
  s.version        = '0.0.1'
  s.license        = 'Commercial'
  s.summary        = 'Parsely analytics library for iOS.'
  s.homepage       = 'https://www.parsely.com/docs/tools/mobile_sdk.html'
  s.author         = { 'Parsely' => 'https://parsely.com' }

  s.source         = { :git => 'https://github.com/segmentio/parsely-ios.git', :tag => '1.0.0' }
  s.source_files   = 'ParselyiOS/*.{h,m}'
end
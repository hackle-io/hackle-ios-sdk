Pod::Spec.new do |s|
  s.name          = "Hackle"
  s.version       = "2.31.0"
  s.summary       = "Hackle Sdk for iOS"
  s.homepage      = "https://www.hackle.io"
  s.license       = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author        = { "Hackle" => "platform@hackle.io" }

  s.source        = { :git => "https://github.com/hackle-io/hackle-ios-sdk.git", :tag => "#{s.version}" }
  s.platform      = :ios, "10.0"
  s.requires_arc  = true
  s.ios.vendored_frameworks = 'Hackle/Hackle.xcframework'
end

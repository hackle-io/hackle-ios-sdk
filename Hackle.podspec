Pod::Spec.new do |spec|
spec.name          = "Hackle"
spec.module_name   = "Hackle"
spec.version       = "2.18.0"
spec.summary       = "Hackle Sdk for iOS"
spec.homepage      = "https://www.hackle.io"
spec.license       = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
spec.author        = { "Hackle" => "platform@hackle.io" }
spec.ios.deployment_target = "10.0"
spec.source        = { :git => "https://github.com/hackle-io/hackle-ios-sdk.git", :tag => "#{spec.version}" }
spec.source_files  = "Sources/**/*.swift"
spec.resources     = "Sources/**/*.{xib,png}"
spec.frameworks    = "Foundation"
spec.swift_version = "5.0"
end

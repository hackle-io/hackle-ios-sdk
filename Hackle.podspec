Pod::Spec.new do |spec|
spec.name          = "Hackle"
spec.module_name   = "Hackle"
spec.version       = "2.42.1"
spec.summary       = "Hackle Sdk for iOS"
spec.homepage      = "https://www.hackle.io"
spec.license       = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
spec.author        = { "Hackle" => "platform@hackle.io" }
spec.ios.deployment_target = "12.0"
spec.source        = { :git => "https://github.com/hackle-io/hackle-ios-sdk.git", :tag => "#{spec.version}" }
spec.source_files  = "Sources/**/*.{swift,h,m}"
spec.resources     = "Sources/**/*.{xib,png}"
spec.resource_bundles = { "Hackle" => ["Sources/Hackle/PrivacyInfo.xcprivacy"] }
spec.frameworks    = "Foundation"
spec.swift_version = "5.0"
end

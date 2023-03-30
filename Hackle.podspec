Pod::Spec.new do |spec|

spec.name          = "Hackle"
spec.module_name   = "Hackle"
spec.version       = "2.17.0"
spec.summary       = "Hackle Sdk for iOS"
spec.homepage      = "https://www.hackle.io"
spec.license       = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
spec.author        = { "Hackle" => "platform@hackle.io" }
spec.source        = { :git => "https://github.com/hackle-io/hackle-ios-sdk.git", :tag => "#{spec.version}" }

spec.ios.deployment_target = "10.0"
spec.source_files      = "Sources/Hackle/**/*.swift", "Sources/Explorer/**/*.swift"
spec.resources         = "Sources/Explorer/**/*.{xib,png}"

spec.frameworks    = "Foundation"
spec.swift_version = "5.0"

end

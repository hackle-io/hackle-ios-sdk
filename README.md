# Hackle SDK for iOS

[![tests](https://github.com/hackle-io/hackle-ios-sdk/actions/workflows/test.yml/badge.svg)](https://github.com/hackle-io/hackle-ios-sdk/actions/workflows/test.yml)
![GitHub release (with filter)](https://img.shields.io/github/v/release/hackle-io/hackle-ios-sdk)


## Install

### CocoaPods

```
pod 'Hackle', '~> 2.26.0'
```

### Swift Package Manager

```swift
// ...
dependencies: [
    .package(url: "https://github.com/hackle-io/hackle-ios-sdk.git", .upToNextMinor("2.26.0"))
],
targets: [
    .target(
        name: "YOUR_TARGET",
        dependencies: ["Hackle"]
    )
],
// ...
```

## Usage

### Initialize

```swift
import Hackle

Hackle.initialize(sdkKey: "<YOUR_APP_SDK_KEY>") {
    // welcome Hackle SDK!
}

let hackleApp = Hackle.app()
```

### Decide the A/B test variation

```swift
let variation = hackleApp.variation(experimentKey: 42)

if variation == "A" {
    awesomeFeature()
} else if variation == "B" {
    moreAwesomeFeature()
}
```

### Decide the Feature

```swift
let isFeatureOn = hackleApp.isFeatureOn(featureKey: 42)

if isFeatureOn {
    moreAwesomeFeature()
} else {
    awesomeFeature()
}
```

### Tracks the event

```swift
hackleApp.track(eventKey: "purchase")
```

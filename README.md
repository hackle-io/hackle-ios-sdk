# Hackle SDK for iOS

## Install

### CocoaPods

```
pod 'Hackle', '~> 2.15.0'
```

### Swift Package Manager

```swift
// ...
dependencies: [
    .package(url: "https://github.com/hackle-io/hackle-ios-sdk.git", .upToNextMinor("2.15.0"))
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
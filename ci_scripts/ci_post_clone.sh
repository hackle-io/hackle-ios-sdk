#!/bin/sh
# SwiftPM 자동 해결 강제 활성화
defaults delete com.apple.dt.Xcode IDEPackageOnlyUseVersionsFromResolvedFile
defaults delete com.apple.dt.Xcode IDEDisableAutomaticPackageResolution

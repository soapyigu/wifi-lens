# Wi-Fi Lens

An iOS app that scans Wi-Fi router labels or cards using the camera, detects network credentials, and connects automatically.

## Features

- Scan Wi-Fi network details via camera
- Auto-connect to detected networks
- On-device processing — no data leaves your phone

## Screens

| # | Screen | Description |
|---|---|---|
| 1 | Welcome | Landing screen with "Start Scanning" CTA |
| 2 | Camera Scanning | Live camera view with animated scanning overlay |
| 3 | Found Wi-Fi Details | Bottom sheet showing detected network name & password |
| 4 | Connecting | Loading state while connecting to the network |
| 5 | Connected | Success confirmation screen |
| 6 | Scanning Warning | Guidance to adjust position or lighting |
| 7 | Connection Failed | Error state with retry option |

## Requirements

- iOS 18+
- Xcode 16+
- Camera permission

## Getting Started

1. Clone the repo
2. Open `WifiLens.xcodeproj` in Xcode
3. Select a simulator or device and press `Cmd+R`

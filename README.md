# Session Linking Demo
An iOS demo app that links a mobile session to a remote session by scanning a QR code, detecting AprilTags in the camera feed, and streaming drawing input over WebSocket.
## Overview
The app walks through a short onboarding flow on device:
1. **Scan a QR code** containing session metadata (`session_id`, `timestamp`).
2. **Detect five AprilTags** (`tag36h11`) in the live camera feed.
3. **POST calibration data** (QR payload + tag positions) to a backend server.
4. **Open a WebSocket** for the session and show a **drawing canvas** that streams touch coordinates to the server in real time.
This is intended as a proof of concept for linking a physical capture session (camera + fiducial markers) with a remote interactive session.
## Requirements
- **Xcode** with iOS 18 SDK
- **Physical iOS device** with a rear camera (camera and AprilTag detection are not practical in Simulator)
- **[AprilTagWrapper](https://github.com/heydoncostello/AprilTagWrapper)** — a local Swift package dependency referenced at `../AprilTagWrapper` relative to this project. Clone or place that package alongside this repo before building.
## Getting Started
1. Clone this repository.
2. Ensure the `AprilTagWrapper` package is available at `../AprilTagWrapper` (sibling directory to `sessionlinkingdemo`).
3. Open `sessionlinkingdemo.xcodeproj` in Xcode.
4. Select your development team and a physical device as the run destination.
5. Build and run (`⌘R`). Grant camera permission when prompted.
## Usage
1. Launch the app — the home screen shows a live camera preview with the prompt **"Scan a QR to begin!"**
2. Point the camera at a QR code whose payload decodes to JSON:
   ```json
   {
     "session_id": "your-session-id",
     "timestamp": 1234567890
   }
   ```
   QR codes may also be URL-encoded or wrapped in a URL with a `data=` query parameter; the app normalizes these formats before decoding.
3. Continue scanning until **five unique AprilTags** are detected in frame.
4. The app sends a POST request with the QR data and tag positions, connects to the session WebSocket, stops the camera, and transitions to the **drawing canvas**.
5. Draw on the canvas — each touch point is sent as JSON over the WebSocket:
   ```json
   { "type": "signature", "x": 120.0, "y": 340.0 }
   ```
## Backend
The app communicates with a test server at `stronghold-test.onrender.com`:
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/send-message/{sessionId}` | POST | Submit QR + AprilTag calibration payload |
| `/ws/{sessionId}/{clientId}` | WebSocket | Real-time drawing coordinate stream |
| `/m` | GET | Web page loaded by the optional `JSWebView` component |
The POST body matches `PayloadDTO`:
```json

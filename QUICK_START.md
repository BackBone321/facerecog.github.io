# Face Recognition Web - Quick Start Guide

## What Was Created

Your Flutter web project is now set up for **real-time face recognition using TensorFlow.js**. Here's what's included:

### Files Modified/Created:
1. **lib/main.dart** - Main UI with basic face recognition
2. **lib/face_recognition_service.dart** - Service layer for face operations
3. **lib/advanced_example.dart** - Advanced usage with streaming detection
4. **web/index.html** - Updated with TensorFlow.js libraries
5. **FACE_RECOGNITION_SETUP.md** - Comprehensive setup documentation

## Quick Start (5 minutes)

### 1. Install Dependencies
```bash
cd c:\Users\jhake\teachable_web
flutter pub get
```

### 2. Run on Web
```bash
flutter run -d chrome
```

Or for Edge browser:
```bash
flutter run -d edge
```

### 3. Test the App
- Opens in your browser
- Click "Start Camera" button
- Grant camera permission when prompted
- See real-time face detection results

## What It Does

✅ Loads TensorFlow.js models in the browser
✅ Accesses your webcam via WebRTC
✅ Detects faces in real-time (every 100ms)
✅ Shows face count and confidence score
✅ Displays detection results in real-time

## Architecture Overview

```
┌─────────────────────────────────────┐
│      Flutter Web UI (Dart)          │
│  - main.dart (Basic UI)             │
│  - advanced_example.dart (Advanced) │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  FaceRecognitionService (Dart)      │
│  - Camera control                   │
│  - Face detection interface         │
│  - Stream management                │
└──────────────┬──────────────────────┘
               │
         JS Interop Bridge
               │
┌──────────────▼──────────────────────┐
│  JavaScript/TensorFlow.js           │
│  - BlazeFace (Face Detection)       │
│  - COCO-SSD (Object Detection)      │
│  - face-api.js (Advanced)           │
└─────────────────────────────────────┘
```

## Key Components

### Main Page (Basic)
- Simple start/stop camera buttons
- Displays current face count
- Shows detection status
- **File:** `lib/main.dart`

### Advanced Page (Full-featured)
- Real-time stats and graphs
- Face detection history
- Detailed face information
- Snapshot capture
- **File:** `lib/advanced_example.dart`
- **To use:** Import and navigate to `AdvancedFaceRecognitionPage()`

### Service Layer
- Handles all camera operations
- Manages TensorFlow.js integration
- Provides streaming detection
- **File:** `lib/face_recognition_service.dart`

## Basic Usage Code

```dart
import 'package:teachable_machine_app/face_recognition_service.dart';

// Get the singleton service
final faceService = FaceRecognitionService();

// 1. Initialize (loads models)
await faceService.initialize();

// 2. Start camera
await faceService.startCamera(width: 640, height: 480);

// 3. Detect faces (one-shot)
final result = await faceService.detectFaces();
print('Faces: ${result.faceCount}');

// OR 4. Continuous detection (stream-based)
final stream = faceService.startDetectionStream(
  interval: Duration(milliseconds: 100),
);

stream.listen((result) {
  print('Detected ${result.faceCount} faces');
});

// 5. Stop when done
faceService.stopCamera();
```

## Performance Tips

| Setting | Recommendation |
|---------|---|
| **Resolution** | 640x480 (balanced) |
| **Detection Interval** | 100ms (real-time) |
| **Model** | BlazeFace (fast) |
| **Browser** | Chrome/Firefox (best) |

To reduce CPU usage:
```dart
// Less frequent detection
stream = faceService.startDetectionStream(
  interval: Duration(milliseconds: 200),  // 200ms instead of 100ms
);

// Lower resolution
await faceService.startCamera(width: 320, height: 240);
```

## Browser Requirements

| Requirement | Status |
|-------------|--------|
| WebRTC (Camera) | ✅ Required |
| HTTPS | ⚠️ Required in production |
| JavaScript enabled | ✅ Required |
| WebGL | ⚠️ Optional (for better performance) |

## Common Tasks

### Task 1: Show Detected Face Coordinates
```dart
final result = await faceService.detectFaces();
for (var face in result.faces) {
  if (face.boundingBox != null) {
    print('Face at: (${face.boundingBox!.x}, ${face.boundingBox!.y})');
    print('Size: ${face.boundingBox!.width}x${face.boundingBox!.height}');
  }
}
```

### Task 2: Count Faces Over Time
```dart
int facesPassed = 0;
faceService.startDetectionStream().listen((result) {
  facesPassed += result.faceCount;
  print('Total people detected: $facesPassed');
});
```

### Task 3: High Confidence Detection Only
```dart
final result = await faceService.detectFaces();
final highConfidence = result.faces
  .where((face) => face.confidence > 0.9)
  .toList();
print('High confidence faces: ${highConfidence.length}');
```

### Task 4: Capture Screenshot
```dart
final snapshot = faceService.captureSnapshot();
// snapshot is an html.CanvasElement you can save/process
```

## Next Steps

### For Basic Implementation:
1. ✅ Run the app with `flutter run -d chrome`
2. Test camera access and face detection
3. Customize the UI in `main.dart`

### For Advanced Features:
1. Use `advanced_example.dart` as reference
2. Add face recognition (identifying specific people)
3. Implement emotion detection
4. Add face authentication

### For Production:
1. Build: `flutter build web --release`
2. Deploy to Firebase, Netlify, or Vercel
3. Set up HTTPS
4. Test on multiple browsers

## Troubleshooting

**Q: Camera not working?**
- Ensure you clicked "Allow" for camera permission
- Check if HTTPS is required (for production)
- Try a different browser

**Q: Models not loading?**
- Check internet connection
- Verify CDN URLs in `web/index.html`
- Check browser console for errors (F12)

**Q: Slow performance?**
- Reduce detection interval (200ms instead of 100ms)
- Lower camera resolution
- Close other browser tabs

**Q: TensorFlow errors in console?**
- Refresh the page
- Clear browser cache
- Check console for specific error messages

## File Locations

```
teachable_web/
├── lib/
│   ├── main.dart                    ← Basic UI
│   ├── face_recognition_service.dart ← Core service
│   └── advanced_example.dart        ← Advanced UI example
├── web/
│   ├── index.html                   ← TensorFlow.js setup
│   ├── flutter_bootstrap.js
│   └── teachable.js
├── pubspec.yaml                     ← Dependencies
└── FACE_RECOGNITION_SETUP.md        ← Full documentation
```

## Next: Advanced Features

Once basic face detection works, try:

```dart
// 1. Face recognition (who is this?)
// - Requires face database
// - Uses face embeddings

// 2. Emotion detection
// - Requires face-api.js extensions
// - Detects happy, sad, angry, etc.

// 3. Age/gender detection
// - Requires demographic models
// - Shows estimated age and gender

// 4. Face mask detection
// - Requires mask detection model
// - Useful for safety compliance
```

## Support Resources

- 📖 Full Guide: See `FACE_RECOGNITION_SETUP.md`
- 🔗 TensorFlow.js: https://www.tensorflow.org/js
- 🚀 Flutter Web: https://flutter.dev/web
- 🎥 WebRTC: https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API

## You're Ready! 🚀

Run this command to start:
```bash
flutter run -d chrome
```

Then click "Start Camera" and see face detection in action!

---

**Questions?** Check `FACE_RECOGNITION_SETUP.md` for detailed documentation.

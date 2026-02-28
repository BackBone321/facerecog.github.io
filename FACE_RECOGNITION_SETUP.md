# Face Recognition Web App - Setup Guide

## Overview
This is a Dart/Flutter web application for real-time face recognition using TensorFlow.js. The app uses multiple face detection models for accurate results.

## Project Structure

```
lib/
├── main.dart                      # Main UI and entry point
└── face_recognition_service.dart  # Face recognition service layer

web/
├── index.html                     # HTML with TensorFlow.js libraries
├── flutter_bootstrap.js           # Flutter web bootstrap
└── teachable.js                   # Additional JavaScript utilities

assets/
├── detect.tflite                  # TensorFlow Lite model
└── labels.txt                     # Model labels
```

## Technologies Used

1. **TensorFlow.js** - JavaScript ML library for browser
2. **BlazeFace** - Lightweight face detection model
3. **COCO-SSD** - General object detection (fallback)
4. **face-api.js** - Advanced face detection and recognition
5. **Flutter Web** - UI framework
6. **Dart** - Programming language

## Installation & Setup

### 1. Get Dependencies
```bash
flutter pub get
```

### 2. Required Pubspec Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  tflite_web: ^0.4.0
  web: ^0.5.0
  js: ^0.6.5
```

### 3. Asset Configuration
Make sure `pubspec.yaml` has assets uncommented:
```yaml
flutter:
  assets:
    - assets/detect.tflite
    - assets/labels.txt
```

## Running the App

### Development
```bash
flutter run -d chrome
# or
flutter run -d edge
```

### Build for Production
```bash
flutter build web --release
```

The build output will be in `build/web/`

## How It Works

### 1. **Model Loading**
The app loads TensorFlow.js and face detection models from CDN:
- TensorFlow.js
- BlazeFace (primary model)
- COCO-SSD (fallback)
- face-api.js (advanced detection)

### 2. **Camera Access**
- Uses WebRTC API (`getUserMedia`) to access the browser camera
- Video stream is processed in real-time

### 3. **Face Detection**
- Frames are analyzed every 100ms (configurable)
- Detects face count, position, confidence score
- Returns bounding boxes and landmarks

### 4. **UI Display**
- Shows real-time detection results
- Displays face count and confidence
- Start/stop camera controls

## Usage Examples

### Basic Usage
```dart
import 'package:teachable_machine_app/face_recognition_service.dart';

// Initialize service
final faceService = FaceRecognitionService();
await faceService.initialize();

// Start camera
await faceService.startCamera(width: 640, height: 480);

// Detect faces
final result = await faceService.detectFaces();
print('Faces detected: ${result.faceCount}');

// Stop camera
faceService.stopCamera();
```

### Stream-based Detection
```dart
// Get continuous detection stream
final detectionStream = faceService.startDetectionStream(
  interval: Duration(milliseconds: 100),
);

detectionStream.listen((result) {
  print('Detected ${result.faceCount} faces');
  for (var face in result.faces) {
    print('Confidence: ${face.confidence}');
    if (face.boundingBox != null) {
      print('Position: (${face.boundingBox!.x}, ${face.boundingBox!.y})');
    }
  }
});
```

### Capture Snapshots
```dart
// Capture current frame
final snapshot = faceService.captureSnapshot();
if (snapshot != null) {
  // You can now save or process the snapshot
  print('Snapshot captured!');
}
```

## Available Models

### 1. BlazeFace
- **Lightweight**: ~100KB
- **Speed**: Real-time on mobile
- **Output**: Face bounding boxes
- **Best for**: Quick detection, low latency

### 2. COCO-SSD
- **General object detection**
- **Can detect people and faces**
- **Output**: Multiple object types with confidence

### 3. face-api.js
- **Feature-rich**: Detects landmarks, expressions, age
- **Slower**: Better accuracy
- **Output**: Face landmarks, expressions, descriptors

## Configuration Options

### Camera Resolution
```dart
await faceService.startCamera(
  width: 1280,  // Higher resolution for accuracy
  height: 720,
);
```

### Detection Interval
```dart
final stream = faceService.startDetectionStream(
  interval: Duration(milliseconds: 50),  // More frequent detection
);
```

## Advanced Features

### Face Landmarks Detection
Detect facial landmarks (eyes, nose, mouth, etc.):
```javascript
// In web/index.html
const detections = await faceapi.detectAllFaces(videoElement)
  .withFaceLandmarks()
  .withFaceExpressions();
```

### Face Recognition/Matching
Compare faces to identify the same person:
```javascript
// Requires face-api extensions
const labeledDescriptors = await Promise.all(
  labels.map(async label =>
    new faceapi.LabeledFaceDescriptors(label, [/* descriptors */])
  )
);
const faceMatcher = new faceapi.FaceMatcher(labeledDescriptors, 0.6);
```

### Custom TensorFlow Models
To use your own trained model:
1. Export model as TensorFlow.js format
2. Host model files on web server
3. Load in `web/index.html`:
```javascript
const model = await tf.loadGraphModel('https://your-server/model.json');
```

## Performance Optimization

1. **Reduce detection frequency** for slower devices
2. **Lower camera resolution** if using high-end models
3. **Use Web Workers** for heavy processing
4. **Cache models** locally

## Troubleshooting

### Camera not working
- Check browser permissions
- Ensure HTTPS (required for camera access)
- Check browser console for errors

### Model loading issues
- Check network connectivity
- Verify CDN URLs are accessible
- Check CORS headers

### Performance issues
- Reduce detection frequency
- Lower camera resolution
- Use lighter model (BlazeFace)
- Close other browser tabs

## Browser Compatibility

| Browser | Status | Notes |
|---------|--------|-------|
| Chrome | ✓ | Full support |
| Firefox | ✓ | Full support |
| Safari | ✓ | Full support (iOS 14.5+) |
| Edge | ✓ | Full support |
| Internet Explorer | ✗ | Not supported |

## Deployment

### Using Firebase Hosting
```bash
firebase init hosting
flutter build web
firebase deploy
```

### Using Netlify
```bash
netlify deploy --prod --dir build/web
```

### Using Vercel
```bash
vercel deploy --prod build/web
```

## Common Use Cases

1. **Security/Access Control** - Face-based authentication
2. **Attendance Tracking** - Automatic attendance marking
3. **Emotion Analysis** - Detect user emotions
4. **Photo Organization** - Tag photos by face
5. **Accessibility** - Control UI with facial gestures

## Next Steps

1. Add face recognition (comparing detected faces)
2. Implement face authentication
3. Add emotion detection
4. Create face database for identification
5. Add age/gender detection
6. Implement face mask detection

## Resources

- [TensorFlow.js Documentation](https://www.tensorflow.org/js)
- [face-api.js](https://github.com/vladmandic/face-api)
- [Flutter Web Documentation](https://flutter.dev/web)
- [WebRTC API](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API)

## Support

For issues or questions:
1. Check browser console for errors
2. Verify all dependencies are installed
3. Ensure web platform is properly set up
4. Test in a different browser

## License

This project is provided as-is for educational purposes.

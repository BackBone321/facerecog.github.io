import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;

/// Service class for face recognition operations using TensorFlow.js
class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  static const String webcamContainerId = 'webcam-container';

  bool _isInitialized = false;
  bool _isCameraRunning = false;
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  StreamController<FaceDetectionResult>? _detectionController;

  FaceRecognitionService._internal();

  factory FaceRecognitionService() {
    return _instance;
  }

  /// Initialize the face recognition service
  Future<bool> initialize() async {
    try {
      print('Initializing FaceRecognitionService...');
      
      // Create a completer to handle the async JavaScript promise
      final completer = Completer<bool>();
      
      // Call the JavaScript initialization function
      print('Calling initializeFaceDetection...');
      final jsPromise = js.context.callMethod('initializeFaceDetection');
      
      // Handle the JavaScript Promise with .then()
      if (jsPromise is js.JsObject && jsPromise['then'] != null) {
        // Success callback
        final successCallback = js.allowInterop((dynamic result) {
          print('✓ JavaScript Promise resolved: $result');
          final success = result == true || result == 'true';
          completer.complete(success);
        });
        
        // Error callback
        final errorCallback = js.allowInterop((dynamic error) {
          print('⚠️ JavaScript Promise rejected: $error');
          completer.complete(false);
        });
        
        // Call .then() on the promise
        jsPromise.callMethod('then', [successCallback, errorCallback]);
      } else {
        // Direct result (synchronous)
        print('⚠️ Result is not a Promise: $jsPromise');
        completer.complete(false);
      }
      
      // Wait for the promise to resolve
      final success = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⚠️ Initialization timeout');
          return false;
        },
      );
      
      if (success) {
        print('✓ Face detection model initialized successfully');
        _isInitialized = true;
      } else {
        print('⚠️ Face detection model failed to initialize');
        _isInitialized = false;
      }
      
      return _isInitialized;
    } catch (e) {
      print('❌ ERROR initializing face recognition: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Start the camera and begin face detection
  Future<bool> startCamera({
    required int width,
    required int height,
  }) async {
    try {
      // Always reset previous state so repeated on/off cycles remain stable.
      if (_isCameraRunning || _videoElement != null) {
        stopCamera();
      }

      // Request camera access
      final constraints = {
        'video': {
          'width': {'ideal': width},
          'height': {'ideal': height},
        }
      };

      final stream =
          await html.window.navigator.mediaDevices!.getUserMedia(constraints);

      // Create video element and make it VISIBLE
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..width = width
        ..height = height
        ..muted = true
        ..style.border = '3px solid #1976d2'
        ..style.borderRadius = '12px'
        ..style.display = 'block'
        ..style.margin = '20px auto'
        ..style.maxWidth = '90%'
        ..style.height = 'auto'
        ..style.objectFit = 'cover'
        ..style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
      _videoElement!.setAttribute('playsinline', 'true');

      _videoElement!.srcObject = stream;

      // Append to webcam-container (created in index.html and rendered in Flutter).
      final container = html.document.querySelector('#$webcamContainerId');
      if (container != null) {
        container.children.clear();
        container.append(_videoElement!);
      } else {
        // Fallback to body if container not found
        html.document.body!.append(_videoElement!);
      }

      // Ensure the element is actually playing before detection starts.
      await _videoElement!.play();

      _isCameraRunning = true;
      return true;
    } catch (e) {
      print('Error starting camera: $e');
      return false;
    }
  }

  /// Stop the camera
  void stopCamera() {
    final video = _videoElement;
    if (video != null) {
      // Stop all tracks safely.
      final mediaStream = video.srcObject;
      if (mediaStream is html.MediaStream) {
        final tracks = mediaStream.getTracks();
        for (final track in tracks) {
          track.stop();
        }
      }

      video.pause();
      video.srcObject = null;
      video.remove();
      _videoElement = null;
    }

    if (_canvasElement != null) {
      _canvasElement!.remove();
      _canvasElement = null;
    }

    _isCameraRunning = false;
  }

  /// Detect faces in the current video stream
  Future<FaceDetectionResult> detectFaces() async {
    if (!_isCameraRunning || _videoElement == null) {
      print('detectFaces: camera not running or video is null');
      return FaceDetectionResult(count: 0, classes: [], predictions: {});
    }

    try {
      print('Calling detectFaces from Dart...');
      
      // Call JavaScript detectFaces function - now synchronous!
      final result = js.context.callMethod('detectFaces', [_videoElement]);
      
      if (result == null) {
        print('detectFaces returned null (video not ready)');
        return FaceDetectionResult(count: 0, classes: [], predictions: {});
      }

      print('detectFaces returned: $result (type: ${result.runtimeType})');

      // Parse the result
      final parsed = FaceDetectionResult.fromJS(result);
      if (parsed.topClass != null) {
        print('✓ Detected: ${parsed.topClass} (${(parsed.topConfidence ?? 0 * 100).toStringAsFixed(1)}%)');
      }
      return parsed;
    } catch (e) {
      print('❌ Error detecting faces: $e');
      return FaceDetectionResult(count: 0, classes: [], predictions: {});
    }
  }

  /// Start continuous face detection and emit results via stream
  Stream<FaceDetectionResult> startDetectionStream({
    Duration interval = const Duration(milliseconds: 100),
  }) async* {
    _detectionController = StreamController<FaceDetectionResult>();

    final timer = Timer.periodic(interval, (_) async {
      if (!_isCameraRunning) return;

      final result = await detectFaces();
      if (!_detectionController!.isClosed) {
        _detectionController!.add(result);
      }
    });

    try {
      yield* _detectionController!.stream;
    } finally {
      timer.cancel();
      await _detectionController!.close();
    }
  }

  /// Capture a snapshot from the video stream
  html.CanvasElement? captureSnapshot() {
    if (_videoElement == null || _canvasElement == null) {
      return null;
    }

    try {
      final context = _canvasElement!.context2D;
      context.drawImage(_videoElement!, 0, 0);
      return _canvasElement;
    } catch (e) {
      print('Error capturing snapshot: $e');
      return null;
    }
  }

  /// Get the current state
  bool get isInitialized => _isInitialized;
  bool get isCameraRunning => _isCameraRunning;
  html.VideoElement? get videoElement => _videoElement;
}

/// Result class for Teachable Machine classification
class FaceDetectionResult {
  final int count;
  final String? topClass;
  final double? topConfidence;
  final List<String> classes;
  final Map<String, double> predictions;

  FaceDetectionResult({
    required this.count,
    this.topClass,
    this.topConfidence,
    required this.classes,
    required this.predictions,
  });

  factory FaceDetectionResult.fromJS(dynamic jsData) {
    try {
      if (jsData == null) {
        return FaceDetectionResult(
          count: 0,
          classes: [],
          predictions: {},
        );
      }

      // Get count
      int count = 0;
      dynamic countValue = jsData['count'];
      if (countValue is int) {
        count = countValue;
      } else if (countValue is double) {
        count = countValue.toInt();
      }

      // Get top classification
      String? topClass = jsData['topClass'] as String?;
      double? topConfidence;
      dynamic confidenceValue = jsData['topConfidence'];
      if (confidenceValue is num) {
        topConfidence = confidenceValue.toDouble();
      }

      // Get classes list
      List<String> classes = [];
      dynamic classList = jsData['classes'];
      if (classList is List) {
        classes = classList.map((c) => c.toString()).toList();
      }

      // Get predictions map
      Map<String, double> predictions = {};
      dynamic predictionsMap = jsData['predictions'];
      if (predictionsMap is Map) {
        predictionsMap.forEach((key, value) {
          if (value is num) {
            predictions[key.toString()] = value.toDouble();
          }
        });
      }

      print('✓ Classification: $topClass (${(topConfidence ?? 0 * 100).toStringAsFixed(1)}%)');
      
      return FaceDetectionResult(
        count: count,
        topClass: topClass,
        topConfidence: topConfidence,
        classes: classes,
        predictions: predictions,
      );
    } catch (e) {
      print('Error parsing classification result: $e');
      return FaceDetectionResult(count: 0, classes: [], predictions: {});
    }
  }

  @override
  String toString() => 'Classification(detected: $topClass, confidence: ${topConfidence?.toStringAsFixed(2)})';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'face/webcam_view_stub.dart'
    if (dart.library.html) 'face/webcam_view_web.dart' as webcam_view;
import 'face_recognition_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  runZonedGuarded(
    () => runApp(const FaceRecognitionApp()),
    (Object error, StackTrace stackTrace) {
      // ignore: avoid_print
      print('Uncaught zone error: $error\n$stackTrace');
    },
  );
}

class FaceRecognitionApp extends StatelessWidget {
  const FaceRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teachable Machine Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FaceRecognitionPage(),
    );
  }
}

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  static const String _webcamViewType = 'webcam-view';

  bool isModelLoaded = false;
  bool isCameraActive = false;
  bool isCameraBusy = false;
  String statusMessage = kIsWeb
      ? 'Loading model...'
      : 'Ready on mobile. Tap Start Camera to begin.';
  String? detectedClass;
  double? confidence;
  Map<String, double> predictions = {};

  Timer? _detectionTimer;
  late final FaceRecognitionService _faceService;

  @override
  void initState() {
    super.initState();
    webcam_view.registerWebcamViewFactory(
      _webcamViewType,
      FaceRecognitionService.webcamContainerId,
    );
    _faceService = FaceRecognitionService();
    if (kIsWeb) {
      _initializeFaceRecognition(autoStart: true);
    } else {
      isModelLoaded = true;
    }
  }

  Future<void> _initializeFaceRecognition({bool autoStart = false}) async {
    try {
      final success = await _faceService.initialize();

      if (!mounted) return;
      setState(() {
        isModelLoaded = success;
        statusMessage = success
            ? (kIsWeb ? 'Model loaded. Starting camera...' : 'Ready on mobile.')
            : (kIsWeb
                ? 'Model failed to load. Check browser console (F12), then retry.'
                : 'Initialization failed on mobile.');
      });

      if (success && mounted && autoStart) {
        await Future.delayed(const Duration(milliseconds: 400));
        await _startCamera();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        statusMessage = 'Error: $e';
      });
      // ignore: avoid_print
      print('Error initializing face recognition: $e');
    }
  }

  Future<void> _startCamera() async {
    if (isCameraBusy) return;

    if (!isModelLoaded) {
      await _initializeFaceRecognition(autoStart: false);
      if (!isModelLoaded) return;
    }

    try {
      setState(() {
        isCameraBusy = true;
        isCameraActive = true;
        statusMessage = 'Starting camera...';
      });

      final success = await _faceService.startCamera(width: 640, height: 480);

      if (!mounted) return;
      if (!success) {
        setState(() {
          isCameraBusy = false;
          isCameraActive = false;
          statusMessage = 'Failed to start camera';
        });
        return;
      }

      setState(() {
        isCameraBusy = false;
        statusMessage = 'Camera started. Detecting...';
      });

      _startDetectionLoop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isCameraBusy = false;
        isCameraActive = false;
        statusMessage = 'Camera error: $e';
      });
      // ignore: avoid_print
      print('Error accessing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (!isCameraActive || isCameraBusy || !_faceService.supportsCameraSwitch) {
      return;
    }

    try {
      setState(() {
        isCameraBusy = true;
        statusMessage = 'Switching camera...';
      });

      final success = await _faceService.switchCamera(width: 640, height: 480);

      if (!mounted) return;
      setState(() {
        isCameraBusy = false;
        statusMessage = success
            ? 'Camera switched. Detecting...'
            : 'Unable to switch camera';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isCameraBusy = false;
        statusMessage = 'Switch camera error: $e';
      });
    }
  }

  void _startDetectionLoop() {
    _detectionTimer?.cancel();
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!isCameraActive) {
        timer.cancel();
        return;
      }

      try {
        final result = await _faceService.detectFaces();
        if (!mounted) return;

        setState(() {
          detectedClass = result.topClass;
          confidence = result.topConfidence;
          predictions = result.predictions;
          statusMessage = result.topClass != null
              ? 'Detected: ${result.topClass}'
              : 'Classifying...';
        });
      } catch (e) {
        // ignore: avoid_print
        print('Classification error: $e');
      }
    });
  }

  void _stopCamera({bool updateUi = true}) {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _faceService.stopCamera();

    if (!updateUi || !mounted) return;
    setState(() {
      isCameraBusy = false;
      isCameraActive = false;
      statusMessage = 'Camera stopped';
      detectedClass = null;
      confidence = null;
      predictions = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachable Machine Classifier'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        isModelLoaded
                            ? (kIsWeb ? 'Model Ready' : 'Mobile Ready')
                            : 'Loading Model',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: isModelLoaded ? Colors.green : Colors.red,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (!isModelLoaded && kIsWeb) ...[
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _initializeFaceRecognition,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Loading Model'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          isModelLoaded && !isCameraActive && !isCameraBusy
                              ? _startCamera
                              : null,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Start Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isCameraActive ? _stopCamera : null,
                      icon: const Icon(Icons.videocam_off),
                      label: const Text('Stop Camera'),
                    ),
                    if (!kIsWeb)
                      OutlinedButton.icon(
                        onPressed:
                            isCameraActive && _faceService.supportsCameraSwitch
                                ? _switchCamera
                                : null,
                        icon: const Icon(Icons.flip_camera_android),
                        label: const Text('Switch Camera'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (kIsWeb)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(maxWidth: 700),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: webcam_view.buildWebcamView(_webcamViewType),
                  ),
                ),
              if (!kIsWeb)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(maxWidth: 700),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _faceService.buildCameraPreview() ??
                        const Center(
                          child: Text(
                            'Camera preview will appear here',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                  ),
                ),
              if (isCameraActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Detection Result',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        detectedClass ?? 'Analyzing...',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 10),
                      if (confidence != null)
                        Text(
                          'Confidence: ${(confidence! * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      const SizedBox(height: 15),
                      if (predictions.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: predictions.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text(
                                      '${(entry.value * 100).toStringAsFixed(1)}%'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopCamera(updateUi: false);
    super.dispose();
  }
}

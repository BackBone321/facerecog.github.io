import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'face_recognition_service.dart';

void main() {
  runApp(const FaceRecognitionApp());
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
  static bool _webcamViewRegistered = false;

  bool isModelLoaded = false;
  bool isCameraActive = false;
  bool isCameraBusy = false;
  String statusMessage = 'Loading model...';
  String? detectedClass;
  double? confidence;
  Map<String, double> predictions = {};

  Timer? _detectionTimer;
  late final FaceRecognitionService _faceService;

  @override
  void initState() {
    super.initState();
    _registerWebcamViewFactory();
    _faceService = FaceRecognitionService();
    _initializeFaceRecognition();
  }

  void _registerWebcamViewFactory() {
    if (!kIsWeb || _webcamViewRegistered) return;

    ui_web.platformViewRegistry.registerViewFactory(_webcamViewType, (int viewId) {
      return html.document.getElementById(FaceRecognitionService.webcamContainerId) ??
          (html.DivElement()
            ..id = FaceRecognitionService.webcamContainerId
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.display = 'flex'
            ..style.justifyContent = 'center'
            ..style.alignItems = 'center'
            ..style.background = '#000');
    });

    _webcamViewRegistered = true;
  }

  Future<void> _initializeFaceRecognition() async {
    try {
      final success = await _faceService.initialize();

      if (!mounted) return;
      setState(() {
        isModelLoaded = success;
        statusMessage = success
            ? 'Model loaded. Starting camera...'
            : 'Model failed to load. Check browser console (F12), then retry.';
      });

      if (success && mounted) {
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
    if (!isModelLoaded || isCameraBusy) return;

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

  void _startDetectionLoop() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
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
                        isModelLoaded ? 'Model Ready' : 'Loading Model',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: isModelLoaded ? Colors.green : Colors.red,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (!isModelLoaded) ...[
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
                      onPressed: isModelLoaded && !isCameraActive && !isCameraBusy
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
                  child: const AspectRatio(
                    aspectRatio: 4 / 3,
                    child: HtmlElementView(viewType: _webcamViewType),
                  ),
                ),
              if (isCameraActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text('${(entry.value * 100).toStringAsFixed(1)}%'),
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

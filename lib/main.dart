import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';
import 'face_recognition_service.dart';

void main() {
  runApp(const FaceRecognitionApp());
}

class FaceRecognitionApp extends StatelessWidget {
  const FaceRecognitionApp({Key? key}) : super(key: key);

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
  const FaceRecognitionPage({Key? key}) : super(key: key);

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  bool isModelLoaded = false;
  bool isCameraActive = false;
  String statusMessage = 'Loading model...';
  String? detectedClass;
  double? confidence;
  Map<String, double> predictions = {};
  
  late final FaceRecognitionService _faceService;

  @override
  void initState() {
    super.initState();
    _faceService = FaceRecognitionService();
    _initializeFaceRecognition();
  }

  Future<void> _initializeFaceRecognition() async {
    try {
      // Initialize the service
      final success = await _faceService.initialize();
      
      setState(() {
        isModelLoaded = success;
        statusMessage = success 
            ? 'Model loaded! Starting camera...' 
            : '⚠️ Model failed to load. Check browser console (F12) for details. Click Retry.';
      });

      // Auto-start camera when model loads
      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        _startCamera();
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
      });
      print('Error initializing face recognition: $e');
    }
  }

  Future<void> _startCamera() async {
    try {
      setState(() {
        isCameraActive = true;
        statusMessage = 'Starting camera...';
      });

      final success = await _faceService.startCamera(width: 640, height: 480);
      
      if (!success) {
        setState(() {
          statusMessage = 'Failed to start camera';
          isCameraActive = false;
        });
        return;
      }

      setState(() {
        statusMessage = 'Camera started! Detecting faces...';
      });

      // Start continuous detection
      _detectFaces();
    } catch (e) {
      setState(() {
        statusMessage = 'Camera error: $e';
        isCameraActive = false;
      });
      print('Error accessing camera: $e');
    }
  }

  void _detectFaces() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!isCameraActive) {
        timer.cancel();
        return;
      }

      try {
        final result = await _faceService.detectFaces();
        
        if (mounted) {
          setState(() {
            detectedClass = result.topClass;
            confidence = result.topConfidence;
            predictions = result.predictions;
            statusMessage = result.topClass != null 
                ? 'Detected: ${result.topClass}'
                : 'Classifying...';
          });

          // Console logging
          if (result.topClass != null && result.topConfidence != null) {
            print('✓ CLASSIFIED: ${result.topClass} (${(result.topConfidence! * 100).toStringAsFixed(1)}%)');
          }
        }
      } catch (e) {
        print('Classification error: $e');
      }
    });
  }

  void _stopCamera() {
    _faceService.stopCamera();
    setState(() {
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Status Card
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        isModelLoaded ? '✓ Model Ready' : '⏳ Loading Model',
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

              // Video Feed Display Note
              if (isCameraActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '📹 Video Feed Displayed Above',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Classification Results
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
                      // Predictions for all classes
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

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: isModelLoaded && !isCameraActive ? _startCamera : null,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Start Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: isCameraActive ? _stopCamera : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
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
    if (isCameraActive) {
      _faceService.stopCamera();
    }
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:teachable_machine_app/face_recognition_service.dart';

/// Advanced face recognition example with stream-based detection
class AdvancedFaceRecognitionPage extends StatefulWidget {
  const AdvancedFaceRecognitionPage({Key? key}) : super(key: key);

  @override
  State<AdvancedFaceRecognitionPage> createState() =>
      _AdvancedFaceRecognitionPageState();
}

class _AdvancedFaceRecognitionPageState extends State<AdvancedFaceRecognitionPage> {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  bool isInitialized = false;
  bool isCameraActive = false;
  List<FaceDetectionResult> detectionHistory = [];
  FaceDetectionResult? latestDetection;
  int totalFacesDetected = 0;
  double averageConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      final success = await _faceService.initialize();
      setState(() {
        isInitialized = success;
      });
    } catch (e) {
      print('Initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _startStreamDetection() async {
    try {
      final cameraStarted = await _faceService.startCamera(
        width: 640,
        height: 480,
      );

      if (!cameraStarted) {
        throw Exception('Failed to start camera');
      }

      setState(() {
        isCameraActive = true;
      });

      // Listen to detection stream
      _faceService.startDetectionStream(
        interval: const Duration(milliseconds: 100),
      ).listen(
        (result) {
          if (mounted) {
            setState(() {
              latestDetection = result;
              detectionHistory.add(result);
              totalFacesDetected += result.faceCount;

              // Keep only last 100 results
              if (detectionHistory.length > 100) {
                detectionHistory.removeAt(0);
              }

              // Calculate average confidence
              if (result.faces.isNotEmpty) {
                final sum = result.faces
                    .fold<double>(0, (prev, face) => prev + face.confidence);
                averageConfidence = sum / result.faces.length;
              }
            });
          }
        },
        onError: (error) {
          print('Stream error: $error');
        },
        onDone: () {
          print('Detection stream closed');
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _stopDetection() {
    _faceService.stopCamera();
    setState(() {
      isCameraActive = false;
      detectionHistory.clear();
      latestDetection = null;
      totalFacesDetected = 0;
      averageConfidence = 0.0;
    });
  }

  void _captureSnapshot() {
    final snapshot = _faceService.captureSnapshot();
    if (snapshot != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot captured!')),
      );
      // You can now process the snapshot or save it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Face Recognition'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Section
              _buildStatusCard(),

              const SizedBox(height: 20),

              // Real-time Detection Stats
              if (isCameraActive && latestDetection != null)
                _buildDetectionStatsCard(),

              const SizedBox(height: 20),

              // Detection History Chart
              if (detectionHistory.isNotEmpty)
                _buildDetectionHistoryCard(),

              const SizedBox(height: 20),

              // Face Details
              if (latestDetection != null && latestDetection!.faces.isNotEmpty)
                _buildFaceDetailsCard(),

              const SizedBox(height: 20),

              // Control Buttons
              _buildControlButtons(),

              const SizedBox(height: 20),

              // Advanced Options
              _buildAdvancedOptionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isInitialized ? Icons.check_circle : Icons.pending,
                  color: isInitialized ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Model Status'),
                    Text(
                      isInitialized ? 'Loaded' : 'Loading...',
                      style: TextStyle(
                        color: isInitialized ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isCameraActive ? Icons.videocam : Icons.videocam_off,
                  color: isCameraActive ? Colors.blue : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Camera Status'),
                    Text(
                      isCameraActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isCameraActive ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionStatsCard() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Detection Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatTile(
                  'Detected Faces',
                  latestDetection!.faceCount.toString(),
                  Colors.blue,
                ),
                _buildStatTile(
                  'Confidence',
                  '${(averageConfidence * 100).toStringAsFixed(1)}%',
                  Colors.green,
                ),
                _buildStatTile(
                  'Last Frame',
                  '${latestDetection!.faces.length} faces',
                  Colors.purple,
                ),
                _buildStatTile(
                  'Total Detected',
                  totalFacesDetected.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionHistoryCard() {
    final recentDetections = detectionHistory.take(10).toList();
    final maxCount =
        recentDetections.fold<int>(0, (max, r) => r.faceCount > max ? r.faceCount : max);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection History (Last 10)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: recentDetections
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final detection = entry.value;
                  final height = maxCount > 0
                      ? (detection.faceCount / maxCount * 80).toDouble()
                      : 0.0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        detection.faceCount.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceDetailsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Face Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...latestDetection!.faces.asMap().entries.map((entry) {
              final index = entry.key;
              final face = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Face #${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${(face.confidence * 100).toStringAsFixed(2)}%',
                      ),
                      if (face.boundingBox != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Position: (${face.boundingBox!.x.toStringAsFixed(0)}, ${face.boundingBox!.y.toStringAsFixed(0)})',
                        ),
                        Text(
                          'Size: ${face.boundingBox!.width.toStringAsFixed(0)}x${face.boundingBox!.height.toStringAsFixed(0)}',
                        ),
                      ],
                      if (face.landmarks != null && face.landmarks!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Landmarks: ${face.landmarks!.length} points',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: isInitialized && !isCameraActive ? _startStreamDetection : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isCameraActive ? _stopDetection : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Colors.red,
          ),
        ),
        ElevatedButton.icon(
          onPressed: isCameraActive ? _captureSnapshot : null,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Capture'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Detection Interval'),
              subtitle: const Text('100ms per frame'),
              leading: const Icon(Icons.schedule),
              onTap: () {
                // Show dialog to adjust interval
              },
            ),
            ListTile(
              title: const Text('Camera Resolution'),
              subtitle: const Text('640x480'),
              leading: const Icon(Icons.photo_size_select_large),
              onTap: () {
                // Show dialog to adjust resolution
              },
            ),
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Save detection results as JSON'),
              leading: const Icon(Icons.download),
              onTap: () {
                // Export detection history
              },
            ),
          ],
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

import 'package:flutter/widgets.dart';

import 'face_types.dart';

abstract class FaceServiceBase {
  Future<bool> initialize();

  Future<bool> startCamera({
    required int width,
    required int height,
  });

  Future<FaceDetectionResult> detectFaces();

  Future<bool> switchCamera({
    required int width,
    required int height,
  });

  bool get supportsCameraSwitch;

  Widget? buildCameraPreview();

  void stopCamera();
}

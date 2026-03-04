import 'package:flutter/widgets.dart';

import 'face/face_service_base.dart';
import 'face/face_service_mobile.dart'
    if (dart.library.html) 'face/face_service_web.dart';
import 'face/face_types.dart';

class FaceRecognitionService {
  static const String webcamContainerId = 'webcam-container';
  final FaceServiceBase _service = createFaceService();

  Future<bool> initialize() => _service.initialize();

  Future<bool> startCamera({
    required int width,
    required int height,
  }) {
    return _service.startCamera(width: width, height: height);
  }

  Future<FaceDetectionResult> detectFaces() => _service.detectFaces();

  Future<bool> switchCamera({
    required int width,
    required int height,
  }) {
    return _service.switchCamera(width: width, height: height);
  }

  bool get supportsCameraSwitch => _service.supportsCameraSwitch;

  Widget? buildCameraPreview() => _service.buildCameraPreview();

  void stopCamera() => _service.stopCamera();
}

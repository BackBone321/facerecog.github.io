import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_service_base.dart';
import 'face_types.dart';

FaceServiceBase createFaceService() => FaceServiceMobile();

class FaceServiceMobile implements FaceServiceBase {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  List<CameraDescription> _availableCameras = <CameraDescription>[];
  CameraLensDirection _activeLensDirection = CameraLensDirection.back;
  bool _isInitialized = false;
  bool _isCameraRunning = false;
  bool _isProcessingFrame = false;
  FaceDetectionResult _lastResult = FaceDetectionResult.empty();

  @override
  Future<bool> initialize() async {
    try {
      _faceDetector?.close();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableClassification: false,
          enableLandmarks: false,
          enableContours: false,
          enableTracking: false,
        ),
      );
      _availableCameras = await availableCameras();
      _isInitialized = true;
      return true;
    } catch (_) {
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<bool> startCamera({
    required int width,
    required int height,
  }) async {
    if (!_isInitialized) {
      final ready = await initialize();
      if (!ready) return false;
    }

    try {
      stopCamera();

      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.isEmpty) {
        return false;
      }

      CameraDescription selected = _availableCameras.first;
      for (final camera in _availableCameras) {
        if (camera.lensDirection == _activeLensDirection) {
          selected = camera;
          break;
        }
      }
      _activeLensDirection = selected.lensDirection;

      final ImageFormatGroup imageFormatGroup = Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888;

      final CameraController controller = CameraController(
        selected,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );
      await controller.initialize();

      await controller.startImageStream((CameraImage image) async {
        if (_isProcessingFrame) return;
        _isProcessingFrame = true;
        try {
          final inputImage = _toInputImage(controller, image);
          if (inputImage == null || _faceDetector == null) {
            _lastResult = FaceDetectionResult.empty();
            return;
          }
          final List<Face> faces =
              await _faceDetector!.processImage(inputImage);
          _lastResult = _classifyFaces(faces);
        } catch (_) {
          _lastResult = FaceDetectionResult.empty();
        } finally {
          _isProcessingFrame = false;
        }
      });

      _cameraController = controller;
      _isCameraRunning = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<FaceDetectionResult> detectFaces() async {
    if (!_isCameraRunning) {
      return FaceDetectionResult.empty();
    }
    return _lastResult;
  }

  @override
  Future<bool> switchCamera({
    required int width,
    required int height,
  }) async {
    if (!supportsCameraSwitch) return false;

    final CameraLensDirection target =
        _activeLensDirection == CameraLensDirection.back
            ? CameraLensDirection.front
            : CameraLensDirection.back;

    final bool hasTarget =
        _availableCameras.any((camera) => camera.lensDirection == target);
    if (!hasTarget) return false;

    _activeLensDirection = target;
    return startCamera(width: width, height: height);
  }

  @override
  bool get supportsCameraSwitch {
    final bool hasFront = _availableCameras
        .any((camera) => camera.lensDirection == CameraLensDirection.front);
    final bool hasBack = _availableCameras
        .any((camera) => camera.lensDirection == CameraLensDirection.back);
    return hasFront && hasBack;
  }

  @override
  Widget? buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }
    return CameraPreview(controller);
  }

  @override
  void stopCamera() {
    final controller = _cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
      _cameraController = null;
    }
    _isCameraRunning = false;
    _isProcessingFrame = false;
    _lastResult = FaceDetectionResult.empty();
  }

  FaceDetectionResult _classifyFaces(List<Face> faces) {
    if (faces.isEmpty) {
      return const FaceDetectionResult(
        count: 0,
        topClass: 'No Face',
        topConfidence: 1,
        classes: <String>['No Face'],
        predictions: <String, double>{'No Face': 1},
      );
    }

    if (faces.length > 1) {
      return FaceDetectionResult(
        count: faces.length,
        topClass: 'Multiple Faces',
        topConfidence: 1,
        classes: const <String>['Multiple Faces', 'Single Face'],
        predictions: const <String, double>{
          'Multiple Faces': 1,
          'Single Face': 0,
        },
      );
    }

    return const FaceDetectionResult(
      count: 1,
      topClass: 'Face Detected',
      topConfidence: 1,
      classes: <String>['Face Detected', 'No Face'],
      predictions: <String, double>{
        'Face Detected': 1,
        'No Face': 0,
      },
    );
  }

  InputImage? _toInputImage(
    CameraController controller,
    CameraImage image,
  ) {
    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final Uint8List bytes = allBytes.done().buffer.asUint8List();

    final InputImageRotation rotation = InputImageRotationValue.fromRawValue(
          controller.description.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;

    final InputImageFormat format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
}

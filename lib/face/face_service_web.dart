// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/widgets.dart';

import 'face_service_base.dart';
import 'face_types.dart';

FaceServiceBase createFaceService() => FaceServiceWeb();

class FaceServiceWeb implements FaceServiceBase {
  static const String webcamContainerId = 'webcam-container';

  bool _isInitialized = false;
  bool _isCameraRunning = false;
  html.VideoElement? _videoElement;

  @override
  Future<bool> initialize() async {
    try {
      final jsPromise = js.context.callMethod('initializeFaceDetection');
      if (jsPromise is! js.JsObject || jsPromise['then'] == null) {
        _isInitialized = false;
        return false;
      }

      final completer = Completer<bool>();
      final successCallback = js.allowInterop((dynamic result) {
        completer.complete(result == true || result == 'true');
      });
      final errorCallback = js.allowInterop((dynamic _) {
        completer.complete(false);
      });
      jsPromise.callMethod('then', <dynamic>[successCallback, errorCallback]);

      _isInitialized = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
      return _isInitialized;
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
    try {
      if (_isCameraRunning || _videoElement != null) {
        stopCamera();
      }

      final Map<String, dynamic> constraints = <String, dynamic>{
        'video': <String, dynamic>{
          'width': <String, int>{'ideal': width},
          'height': <String, int>{'ideal': height},
        }
      };

      final stream =
          await html.window.navigator.mediaDevices!.getUserMedia(constraints);

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

      final container = html.document.querySelector('#$webcamContainerId');
      if (container != null) {
        container.children.clear();
        container.append(_videoElement!);
      } else {
        html.document.body?.append(_videoElement!);
      }

      await _videoElement!.play();
      _isCameraRunning = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<FaceDetectionResult> detectFaces() async {
    if (!_isCameraRunning || _videoElement == null) {
      return FaceDetectionResult.empty();
    }

    try {
      final dynamic result =
          js.context.callMethod('detectFaces', <dynamic>[_videoElement]);
      if (result == null) {
        return FaceDetectionResult.empty();
      }
      return FaceDetectionResult.fromJS(result);
    } catch (_) {
      return FaceDetectionResult.empty();
    }
  }

  @override
  Future<bool> switchCamera({
    required int width,
    required int height,
  }) async {
    return false;
  }

  @override
  bool get supportsCameraSwitch => false;

  @override
  Widget? buildCameraPreview() => null;

  @override
  void stopCamera() {
    final video = _videoElement;
    if (video != null) {
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

    _isCameraRunning = false;
  }
}

class FaceDetectionResult {
  final int count;
  final String? topClass;
  final double? topConfidence;
  final List<String> classes;
  final Map<String, double> predictions;

  const FaceDetectionResult({
    required this.count,
    this.topClass,
    this.topConfidence,
    required this.classes,
    required this.predictions,
  });

  factory FaceDetectionResult.empty() {
    return const FaceDetectionResult(
      count: 0,
      classes: <String>[],
      predictions: <String, double>{},
    );
  }

  factory FaceDetectionResult.fromJS(dynamic jsData) {
    if (jsData == null) {
      return FaceDetectionResult.empty();
    }

    int count = 0;
    final dynamic countValue = jsData['count'];
    if (countValue is int) {
      count = countValue;
    } else if (countValue is double) {
      count = countValue.toInt();
    }

    final String? topClass = jsData['topClass'] as String?;
    double? topConfidence;
    final dynamic confidenceValue = jsData['topConfidence'];
    if (confidenceValue is num) {
      topConfidence = confidenceValue.toDouble();
    }

    List<String> classes = <String>[];
    final dynamic classList = jsData['classes'];
    if (classList is List) {
      classes = classList.map((dynamic c) => c.toString()).toList();
    }

    final Map<String, double> predictions = <String, double>{};
    final dynamic predictionsMap = jsData['predictions'];
    if (predictionsMap is Map) {
      predictionsMap.forEach((dynamic key, dynamic value) {
        if (value is num) {
          predictions[key.toString()] = value.toDouble();
        }
      });
    }

    return FaceDetectionResult(
      count: count,
      topClass: topClass,
      topConfidence: topConfidence,
      classes: classes,
      predictions: predictions,
    );
  }
}

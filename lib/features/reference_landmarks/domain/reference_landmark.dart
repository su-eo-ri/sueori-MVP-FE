import 'package:scoring_poc/scoring_poc.dart';

/// `03-PM-Planning/수어리 - 데이터 모델 (ERD)` 기준 ReferenceLandmark 엔티티.
/// `frames`는 시간 순서 시퀀스(정적 단어는 length=1) — 실시간 카메라가 내놓는
/// 원본 좌표계(정규화된 이미지 좌표 0~1, WRIST 기준 정규화 이전)와 동일해서
/// `mediapipe_bridge.js`의 캔버스 렌더링과 같은 방식으로 그대로 겹쳐 그릴 수 있다.
class ReferenceHandFrame {
  const ReferenceHandFrame({required this.landmarks, this.handedness});

  final List<Point3> landmarks;
  final String? handedness;

  factory ReferenceHandFrame.fromJson(Map<String, dynamic> json) => ReferenceHandFrame(
    landmarks: (json['landmarks'] as List)
        .cast<Map<String, dynamic>>()
        .map((p) => Point3((p['x'] as num).toDouble(), (p['y'] as num).toDouble(), (p['z'] as num).toDouble()))
        .toList(),
    handedness: json['handedness'] as String?,
  );
}

class ReferenceLandmark {
  const ReferenceLandmark({
    required this.id,
    required this.wordId,
    required this.frames,
    required this.modelVersion,
  });

  final String id;
  final String wordId;
  final List<ReferenceHandFrame> frames;
  final String modelVersion;

  factory ReferenceLandmark.fromJson(Map<String, dynamic> json) => ReferenceLandmark(
    id: json['id'] as String,
    wordId: json['word_id'] as String,
    frames: (json['frames'] as List).cast<Map<String, dynamic>>().map(ReferenceHandFrame.fromJson).toList(),
    modelVersion: json['model_version'] as String,
  );
}

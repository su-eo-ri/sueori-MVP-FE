import 'package:scoring_poc/scoring_poc.dart';

import 'word_type.dart';

/// 채점용으로 캡처한 사용자 프레임 한 장. [tMs]는 캡처 시작 기준 경과 시간.
class CapturedFrame {
  const CapturedFrame({required this.tMs, required this.points, this.handedness});

  final int tMs;
  final List<Point3> points;
  final String? handedness;
}

/// `practice_sessions.comparison_summary`(ERD 2026-09-07 스펙) 생성.
///
/// 정적은 유일한 프레임 쌍을, 동적은 사용자 프레임을 기준 시퀀스에 길이 비례로
/// 대응시킨 쌍들 중 평균 관절 오차가 가장 큰 순간을 대표 프레임으로 기록한다.
Map<String, dynamic> buildComparisonSummary({
  required WordType wordType,
  required List<List<Point3>> referenceFrames,
  required List<CapturedFrame> userFrames,
}) {
  var userIndex = 0;
  var referenceIndex = 0;
  if (wordType == WordType.dynamicSign) {
    var worst = -1.0;
    for (var i = 0; i < userFrames.length; i++) {
      final j = _proportionalIndex(i, userFrames.length, referenceFrames.length);
      final d = averageLandmarkDistance(
        normalizeAndFlatten(userFrames[i].points),
        normalizeAndFlatten(referenceFrames[j]),
      );
      if (d > worst) {
        worst = d;
        userIndex = i;
        referenceIndex = j;
      }
    }
  }

  final user = userFrames[userIndex];
  final deltas = _perLandmarkDeltas(
    normalizeAndFlatten(user.points),
    normalizeAndFlatten(referenceFrames[referenceIndex]),
  );
  final weakest = List<int>.generate(deltas.length, (i) => i)
    ..sort((a, b) => deltas[b].compareTo(deltas[a]));

  return {
    'version': 1,
    'algorithm': wordType == WordType.staticSign ? 'distance' : 'dtw',
    'referenceFrameIndex': referenceIndex,
    'userTimestampMs': user.tMs,
    'handedness': user.handedness?.toLowerCase(),
    'userLandmarks': [for (final p in user.points) [_r(p.x), _r(p.y), _r(p.z)]],
    'landmarkDeltas': [for (final d in deltas) _r(d)],
    'weakestLandmarks': weakest.take(3).toList(),
  };
}

int _proportionalIndex(int i, int userLength, int referenceLength) {
  if (userLength <= 1 || referenceLength <= 1) return 0;
  return (i * (referenceLength - 1) / (userLength - 1)).round();
}

List<double> _perLandmarkDeltas(List<double> a, List<double> b) {
  return [
    for (var i = 0; i < a.length ~/ 3; i++)
      averageLandmarkDistance(a.sublist(i * 3, i * 3 + 3), b.sublist(i * 3, i * 3 + 3)),
  ];
}

double _r(double v) => (v * 10000).roundToDouble() / 10000;

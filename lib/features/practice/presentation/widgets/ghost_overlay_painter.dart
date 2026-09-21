import 'package:flutter/material.dart';
import 'package:scoring_poc/scoring_poc.dart';

/// MediaPipe 21포인트 손 스켈레톤 연결 목록 — `web/js/mediapipe_bridge.js`의
/// `CONNECTIONS` 상수와 동일.
const _handConnections = [
  [0, 1], [1, 2], [2, 3], [3, 4],
  [0, 5], [5, 6], [6, 7], [7, 8],
  [5, 9], [9, 10], [10, 11], [11, 12],
  [9, 13], [13, 14], [14, 15], [15, 16],
  [13, 17], [17, 18], [18, 19], [19, 20],
  [0, 17],
];

/// 정답 동작 고스트 오버레이 — 반투명 스켈레톤을 카메라 프리뷰 위에 그린다.
///
/// [landmarks]의 x/y는 라이브 카메라와 동일한 정규화 이미지 좌표(0~1,
/// WRIST 기준 정규화 이전)라서 별도 변환 없이 `point.x * size.width`로
/// 바로 매핑한다.
class GhostOverlayPainter extends CustomPainter {
  const GhostOverlayPainter({required this.landmarks});

  final List<Point3> landmarks;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    Offset toOffset(Point3 p) => Offset(p.x * size.width, p.y * size.height);

    for (final connection in _handConnections) {
      final start = connection[0];
      final end = connection[1];
      if (start >= landmarks.length || end >= landmarks.length) continue;
      canvas.drawLine(toOffset(landmarks[start]), toOffset(landmarks[end]), linePaint);
    }

    for (final point in landmarks) {
      canvas.drawCircle(toOffset(point), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GhostOverlayPainter oldDelegate) => oldDelegate.landmarks != landmarks;
}

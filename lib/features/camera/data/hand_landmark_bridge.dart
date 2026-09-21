// web/js/mediapipe_bridge.js(SueoriHandLandmark)로의 dart:js_interop 브릿지.
// poc/hand_landmark_poc의 JS interop 패턴을 그대로 따르되, 그 PoC엔 없던
// getLandmarks()를 추가로 호출해서 실제 채점에 쓸 좌표를 Dart로 가져온다.
//
// numHands=2라 손이 2개까지 잡힐 수 있음(2026-09-19, "동생" 같은 두 손 수어를
// 한 손만 추적해서 궤적이 불안정해지던 문제 대응) — getLandmarks()가 감지된
// 손마다(handedness 포함) 리스트를 반환한다. 현재 채점 로직(scoring_poc)은
// 아직 한 손(21개 점) 기준이라, getPrimaryHandPoints()로 첫 번째 손만 뽑아서
// 기존 채점 경로와 호환되게 유지한다 — 두 손 채점 지원은 별도 작업.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:scoring_poc/scoring_poc.dart';

@JS('SueoriHandLandmark.start')
external JSPromise<JSAny?> _jsStart(JSString videoId, JSString canvasId);

@JS('SueoriHandLandmark.stop')
external void _jsStop();

@JS('SueoriHandLandmark.getStats')
external JSString _jsGetStats();

@JS('SueoriHandLandmark.getLandmarks')
external JSString _jsGetLandmarks();

/// 한 손의 랜드마크 21개 + 어느 손인지(Left/Right, MediaPipe 판정 기준).
class HandLandmark {
  const HandLandmark({required this.handedness, required this.points});

  final String? handedness;
  final List<Point3> points;
}

class HandLandmarkBridge {
  const HandLandmarkBridge();

  Future<void> start({required String videoElementId, required String canvasElementId}) {
    return _jsStart(videoElementId.toJS, canvasElementId.toJS).toDart;
  }

  void stop() => _jsStop();

  /// 모델 로드/추론 성능 통계(loaded, delegate, fps, numHands 등). 파싱 실패 시 빈 맵.
  Map<String, dynamic> getStats() {
    try {
      return jsonDecode(_jsGetStats().toDart) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// 현재 프레임에서 감지된 손 전부(최대 2개). 손이 안 보이면(또는 아직
  /// 시작 전) null.
  List<HandLandmark>? getLandmarks() {
    final raw = _jsGetLandmarks().toDart;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.cast<Map<String, dynamic>>().map((h) {
        final points = (h['landmarks'] as List)
            .cast<Map<String, dynamic>>()
            .map((p) => Point3((p['x'] as num).toDouble(), (p['y'] as num).toDouble(), (p['z'] as num).toDouble()))
            .toList();
        return HandLandmark(handedness: h['handedness'] as String?, points: points);
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// 기존(한 손 기준) 채점 경로와 호환용 — 감지된 손 중 첫 번째의 21개 점만.
  /// 두 손 채점을 지원하게 되면 이 메서드는 없어질 예정.
  List<Point3>? getPrimaryHandPoints() {
    final hands = getLandmarks();
    if (hands == null || hands.isEmpty) return null;
    return hands.first.points;
  }
}

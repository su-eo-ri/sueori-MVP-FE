// web/js/mediapipe_bridge.js(SueoriHandLandmark)로의 dart:js_interop 브릿지.
// poc/hand_landmark_poc의 JS interop 패턴을 그대로 따르되, 그 PoC엔 없던
// getLandmarks()를 추가로 호출해서 실제 채점에 쓸 좌표를 Dart로 가져온다.

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

class HandLandmarkBridge {
  const HandLandmarkBridge();

  Future<void> start({required String videoElementId, required String canvasElementId}) {
    return _jsStart(videoElementId.toJS, canvasElementId.toJS).toDart;
  }

  void stop() => _jsStop();

  /// 모델 로드/추론 성능 통계(loaded, delegate, fps 등). 파싱 실패 시 빈 맵.
  Map<String, dynamic> getStats() {
    try {
      return jsonDecode(_jsGetStats().toDart) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// 현재 프레임의 21개 손 랜드마크. 손이 안 보이면(또는 아직 시작 전) null.
  List<Point3>? getLandmarks() {
    final raw = _jsGetLandmarks().toDart;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .cast<Map<String, dynamic>>()
          .map((p) => Point3((p['x'] as num).toDouble(), (p['y'] as num).toDouble(), (p['z'] as num).toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }
}

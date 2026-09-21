// 실제 카메라 랜드마크 시퀀스를 녹화해서 JSON으로 다운로드하는 도구.
// scoring_poc의 decayFactor가 synthetic 데이터로만 역산돼 있어서 실측
// 데이터가 필요하다는 게 이미 밝혀진 갭 — 이 파일로 그 실측 데이터를 모은다.
//
// schemaVersion 2 (2026-09-19): 감지된 손 전부(최대 2개, handedness 포함)를
// 저장한다 — "동생"처럼 두 손을 쓰는 수어를 한 손만 기록해서 궤적이 불안정해
// 지던 문제 대응. schemaVersion 1(프레임당 손 하나, 'landmarks' 키가 프레임
// 최상위)로 저장된 예전 파일과는 형식이 다르니 분석 스크립트에서 구분할 것.

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'hand_landmark_bridge.dart';

class _RecordedFrame {
  _RecordedFrame({required this.tMs, required this.hands});
  final int tMs;
  final List<HandLandmark> hands;

  Map<String, dynamic> toJson() => {
    't': tMs,
    'hands': hands
        .map(
          (h) => {
            'handedness': h.handedness,
            'landmarks': h.points.map((p) => {'x': p.x, 'y': p.y, 'z': p.z}).toList(),
          },
        )
        .toList(),
  };
}

/// 카메라에서 나오는 손 랜드마크 프레임(최대 2개 손)을 일정 간격으로 모아뒀다가,
/// 중지 시 `{schemaVersion, label, capturedAt, frameCount, frames}` JSON으로
/// 브라우저 다운로드를 트리거한다. Flutter Web 샌드박스에서 로컬 파일에 직접
/// 쓸 수 없어서 다운로드 방식을 쓴다 — 기본 다운로드 폴더에 저장됨.
class LandmarkRecorder {
  final List<_RecordedFrame> _frames = [];
  DateTime? _startedAt;

  bool get isRecording => _startedAt != null;
  int get frameCount => _frames.length;

  void start() {
    _frames.clear();
    _startedAt = DateTime.now();
  }

  /// 손이 안 보이는 프레임(null 또는 빈 리스트)은 조용히 건너뛴다.
  void addFrame(List<HandLandmark>? hands) {
    if (_startedAt == null || hands == null || hands.isEmpty) return;
    final t = DateTime.now().difference(_startedAt!).inMilliseconds;
    _frames.add(_RecordedFrame(tMs: t, hands: hands));
  }

  /// 녹화를 멈추고 지금까지 모은 프레임을 JSON 파일로 다운로드한다.
  /// 반환값은 실제로 저장된 프레임 개수(0이면 다운로드도 스킵).
  int stopAndDownload(String label) {
    final count = _frames.length;
    _startedAt = null;
    if (count == 0) {
      _frames.clear();
      return 0;
    }
    final safeLabel = label.trim().isEmpty ? 'unlabeled' : label.trim();
    final payload = {
      'schemaVersion': 2,
      'label': safeLabel,
      'capturedAt': DateTime.now().toIso8601String(),
      'frameCount': count,
      'frames': _frames.map((f) => f.toJson()).toList(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final filename = 'landmarks_${_sanitize(safeLabel)}_$ts.json';
    _download(filename, jsonStr);
    _frames.clear();
    return count;
  }

  void cancel() {
    _startedAt = null;
    _frames.clear();
  }

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9가-힣_-]'), '_');

  void _download(String filename, String content) {
    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}

import 'dart:math' as math;

import 'point3.dart';

/// 21개 손 랜드마크를 정규화한 뒤 63차원(21*3) 벡터로 펼친다.
///
/// 정규화 방식:
///  - 손목(0번)을 원점으로 평행이동 → 화면상 손의 위치(어디서 채점하든)와 무관해짐
///  - 손바닥 5점(손목 0, MCP 5·9·13·17) 사이 거리 중 최댓값으로 스케일 정규화 →
///    카메라와의 거리(손 크기)와 무관해짐. 손목~MCP9 한 구간만 쓰면 손을 돌릴 때
///    그 거리가 40~50%까지 줄어 전체 좌표가 부풀려지므로(가족 단어 기준 데이터에서
///    확인), 회전에 덜 민감한 여러 쌍의 최댓값을 쓴다.
///
/// 의도적으로 정규화하지 "않는" 것: 회전(손 방향/손바닥이 향하는 방향).
/// 수어에서는 손바닥이 향하는 방향 자체가 의미를 구분하는 요소인 경우가 많아
/// (예: 같은 손모양이라도 손바닥 방향이 다르면 다른 뜻), 회전을 정규화해버리면
/// 채점이 오히려 부정확해질 수 있다고 판단.
///
/// **알려진 한계 (열린 질문으로 남김)**: 이 정규화는 프레임마다 손목을 원점으로
/// 되돌리기 때문에, "손 전체가 화면에서 어느 방향으로 이동하는지"(궤적) 정보가
/// 사라진다. 동적 수어(단어) 중에는 손모양은 그대로 유지한 채 손의 위치 이동
/// 자체가 의미를 구성하는 경우가 있어, 실제 데이터로 채점 정확도를 검증할 때
/// 이 부분이 부족하면 "손목의 정규화 전 좌표 변화량"을 별도 피처로 추가하는
/// 방안을 검토해야 한다.
const _palm = [0, 5, 9, 13, 17];

List<double> normalizeAndFlatten(List<Point3> landmarks) {
  assert(
    landmarks.length == 21,
    '손 랜드마크는 21개여야 함 (MediaPipe HandLandmarker 기준), 받은 개수: ${landmarks.length}',
  );

  final wrist = landmarks[0];
  var scale = 0.0;
  for (var i = 0; i < _palm.length; i++) {
    for (var j = i + 1; j < _palm.length; j++) {
      final a = landmarks[_palm[i]];
      final b = landmarks[_palm[j]];
      final dx = a.x - b.x;
      final dy = a.y - b.y;
      final dz = a.z - b.z;
      scale = math.max(scale, math.sqrt(dx * dx + dy * dy + dz * dz));
    }
  }
  final safeScale = scale < 1e-9 ? 1.0 : scale;

  final out = List<double>.filled(landmarks.length * 3, 0);
  for (var i = 0; i < landmarks.length; i++) {
    out[i * 3] = (landmarks[i].x - wrist.x) / safeScale;
    out[i * 3 + 1] = (landmarks[i].y - wrist.y) / safeScale;
    out[i * 3 + 2] = (landmarks[i].z - wrist.z) / safeScale;
  }
  return out;
}

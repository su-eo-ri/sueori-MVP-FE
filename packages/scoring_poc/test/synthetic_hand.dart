import 'package:scoring_poc/scoring_poc.dart';

/// 테스트용 합성(synthetic) 손 랜드마크 데이터.
/// **실제 MediaPipe 출력이 아니다** — 알고리즘(코사인 유사도, DTW) 자체가
/// 기대한 대로 동작하는지 검증하기 위해 만든, 그럴듯한 21포인트 손 모양이다.
/// (진짜 카메라 데이터 연동 검증은 hand_landmark_poc 쪽 PoC 담당)

/// "펼친 손" 기준 포즈 — 손가락이 모두 곧게 펴진 상태.
final List<Point3> openHandPose = [
  const Point3(0.50, 0.90, 0.0), // 0 wrist
  const Point3(0.43, 0.82, 0.0), // 1 thumb_cmc
  const Point3(0.38, 0.72, 0.0), // 2 thumb_mcp
  const Point3(0.34, 0.63, 0.0), // 3 thumb_ip
  const Point3(0.30, 0.55, 0.0), // 4 thumb_tip
  const Point3(0.47, 0.65, 0.0), // 5 index_mcp
  const Point3(0.46, 0.50, 0.0), // 6 index_pip
  const Point3(0.45, 0.40, 0.0), // 7 index_dip
  const Point3(0.44, 0.30, 0.0), // 8 index_tip
  const Point3(0.52, 0.63, 0.0), // 9 middle_mcp
  const Point3(0.52, 0.47, 0.0), // 10 middle_pip
  const Point3(0.52, 0.35, 0.0), // 11 middle_dip
  const Point3(0.52, 0.24, 0.0), // 12 middle_tip
  const Point3(0.57, 0.65, 0.0), // 13 ring_mcp
  const Point3(0.58, 0.50, 0.0), // 14 ring_pip
  const Point3(0.59, 0.40, 0.0), // 15 ring_dip
  const Point3(0.60, 0.30, 0.0), // 16 ring_tip
  const Point3(0.62, 0.68, 0.0), // 17 pinky_mcp
  const Point3(0.64, 0.56, 0.0), // 18 pinky_pip
  const Point3(0.65, 0.48, 0.0), // 19 pinky_dip
  const Point3(0.66, 0.40, 0.0), // 20 pinky_tip
];

/// "주먹" 기준 포즈 — 손가락 끝(tip/dip/pip)이 각 mcp 쪽으로 말려 들어간 상태.
/// wrist/mcp 관절은 펼친 손과 동일(둘 다 손바닥 자체는 크게 움직이지 않는다고 가정).
final List<Point3> fistPose = [
  openHandPose[0], // wrist
  openHandPose[1], // thumb_cmc
  openHandPose[2], // thumb_mcp
  const Point3(0.36, 0.76, 0.0), // thumb_ip (말림)
  const Point3(0.39, 0.79, 0.0), // thumb_tip (말림, mcp 근처로)
  openHandPose[5], // index_mcp
  const Point3(0.47, 0.60, 0.0), // index_pip
  const Point3(0.48, 0.64, 0.0), // index_dip
  const Point3(0.49, 0.66, 0.0), // index_tip (mcp 근처로 말림)
  openHandPose[9], // middle_mcp
  const Point3(0.52, 0.58, 0.0), // middle_pip
  const Point3(0.53, 0.62, 0.0), // middle_dip
  const Point3(0.53, 0.64, 0.0), // middle_tip
  openHandPose[13], // ring_mcp
  const Point3(0.57, 0.60, 0.0), // ring_pip
  const Point3(0.57, 0.63, 0.0), // ring_dip
  const Point3(0.57, 0.65, 0.0), // ring_tip
  openHandPose[17], // pinky_mcp
  const Point3(0.62, 0.62, 0.0), // pinky_pip
  const Point3(0.62, 0.65, 0.0), // pinky_dip
  const Point3(0.62, 0.67, 0.0), // pinky_tip
];

Point3 _lerp(Point3 a, Point3 b, double t) =>
    Point3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t);

/// 두 기준 포즈 사이를 t(0=fist, 1=open)로 선형 보간한 포즈.
List<Point3> lerpPose(double t) => [
      for (var i = 0; i < openHandPose.length; i++)
        _lerp(fistPose[i], openHandPose[i], t),
    ];

/// 아주 작은 무작위 노이즈를 섞는다 (사용자가 "거의 맞지만 완벽하진 않게" 따라한 상황 흉내).
List<Point3> withNoise(List<Point3> pose, double magnitude, int seedOffset) {
  return [
    for (var i = 0; i < pose.length; i++)
      Point3(
        pose[i].x + _pseudoNoise(i * 3 + seedOffset) * magnitude,
        pose[i].y + _pseudoNoise(i * 3 + 1 + seedOffset) * magnitude,
        pose[i].z + _pseudoNoise(i * 3 + 2 + seedOffset) * magnitude,
      ),
  ];
}

/// 결정적(deterministic) 의사 노이즈 — 테스트 재현성을 위해 dart:math Random 대신 사용.
double _pseudoNoise(int seed) {
  final v = (seed * 12.9898) % 1.0;
  return (v * 2) - 1; // [-1, 1]
}

/// "주먹 쥐었다 펴기" 동작을 n프레임 시퀀스로 만든다: 0 -> 1 -> 0 삼각파.
/// n=10 기준 정답 시연이라고 가정.
List<List<Point3>> triangularWaveSequence(int n) {
  return [
    for (var i = 0; i < n; i++)
      lerpPose(_triangular(i / (n - 1))),
  ];
}

double _triangular(double t) => t <= 0.5 ? (t * 2) : (2 - t * 2);

/// [original] 시퀀스를 [newLength] 프레임으로 다시 샘플링한다.
/// "정확히 같은 동작을, 다른 프레임레이트(다른 속도)로 녹화했다"를 흉내내기 위해
/// 각 랜드마크를 프레임 축 방향으로 선형 보간한다. (단순히 삼각파 함수를 다른 n으로
/// 독립적으로 재평가하면 두 그리드가 정확히 겹치지 않아 이산화 오차가 섞여
/// "속도 차이"와 "진짜 모양 차이"를 구분하기 어려워지므로, 원본을 직접 보간한다.)
List<List<Point3>> resampleSequence(
  List<List<Point3>> original,
  int newLength,
) {
  final n = original.length;
  if (n == 0 || newLength <= 0) return [];
  if (newLength == 1) return [original[0]];

  return List.generate(newLength, (i) {
    final virtualIndex = i * (n - 1) / (newLength - 1);
    final lower = virtualIndex.floor().clamp(0, n - 1);
    final upper = (lower + 1).clamp(0, n - 1);
    final t = virtualIndex - lower;
    if (lower == upper) return original[lower];
    return [
      for (var j = 0; j < original[lower].length; j++)
        _lerp(original[lower][j], original[upper][j], t),
    ];
  });
}

/// 같은 "주먹 쥐었다 펴기" 동작이지만 다른 프레임 수(다른 속도)로 만든 시퀀스.
/// DTW라면 이걸 원본과 거의 동일하게 채점해야 한다 (시간축 정렬로 흡수).
List<List<Point3>> triangularWaveSequenceResampled(int n) =>
    resampleSequence(triangularWaveSequence(10), n);

/// 다른 모양의 동작: 그냥 펴기만 하고 다시 쥐지 않음(단조 증가). 모양 자체가 다름.
List<List<Point3>> monotonicOpenSequence(int n) {
  return [for (var i = 0; i < n; i++) lerpPose(i / (n - 1))];
}

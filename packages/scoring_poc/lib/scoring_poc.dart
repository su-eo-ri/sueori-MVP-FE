/// 수어리 PoC #2 — 채점 알고리즘 (정적: 코사인 유사도 / 동적: DTW)
///
/// PRD 5.1의 채점 알고리즘 선택이 실제로 "말이 되는 동작"을 하는지 검증하는 PoC.
/// 카메라/MediaPipe 연동은 hand_landmark_poc가 담당하고, 이 패키지는 그 출력물인
/// "21개 랜드마크(프레임 1개) / 랜드마크 시퀀스(프레임 여러 개)"를 입력받아
/// 0~100 점수를 내는 순수 로직만 검증한다.
library;

export 'src/cosine_scorer.dart';
export 'src/distance_scorer.dart';
export 'src/dtw_scorer.dart';
export 'src/landmark_distance.dart';
export 'src/normalize.dart';
export 'src/point3.dart';

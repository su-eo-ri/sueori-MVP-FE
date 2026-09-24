import 'package:scoring_poc/scoring_poc.dart';

import '../../reference_landmarks/domain/reference_landmark.dart';
import 'comparison_summary.dart';
import 'scoring_service.dart';
import 'word_type.dart';

const kDefaultRecordingDuration = Duration(seconds: 3);

/// 동적 단어 녹화 길이: 기준 동작 길이 × 1.2, 2~8초. 기준에 tMs가 없으면 3초.
Duration recordingDurationFor(List<ReferenceHandFrame> frames) {
  final first = frames.isEmpty ? null : frames.first.tMs;
  final last = frames.isEmpty ? null : frames.last.tMs;
  if (first == null || last == null || last <= first) return kDefaultRecordingDuration;
  return Duration(milliseconds: ((last - first) * 1.2).round().clamp(2000, 8000));
}

class HandTrackScore {
  const HandTrackScore({required this.score, required this.frames});

  final double score;
  final List<CapturedFrame> frames;
}

/// 캡처한 프레임을 손(handedness)별로 나눠 각각 채점하고 가장 높은 점수를 쓴다.
/// 전면 카메라 미러링 때문에 라벨을 기준 데이터와 맞추는 방식은 믿기 어려워서,
/// 양손이 잡히면 둘 다 채점한다. 좌표가 비정상(NaN 등)인 손은 건너뛴다.
HandTrackScore? scoreBestHand({
  required ScoringService service,
  required WordType wordType,
  required List<List<Point3>> referenceFrames,
  required List<CapturedFrame> captured,
  int minFrames = 1,
}) {
  final tracks = <String, List<CapturedFrame>>{};
  for (final frame in captured) {
    tracks.putIfAbsent(frame.handedness ?? '', () => []).add(frame);
  }
  HandTrackScore? best;
  for (final track in tracks.values) {
    if (track.length < minFrames) continue;
    try {
      final score = service
          .score(wordType: wordType, referenceFrames: referenceFrames, candidateFrames: track.map((f) => f.points).toList())
          .score;
      if (best == null || score > best.score) best = HandTrackScore(score: score, frames: track);
    } on ArgumentError {
      continue;
    }
  }
  return best;
}

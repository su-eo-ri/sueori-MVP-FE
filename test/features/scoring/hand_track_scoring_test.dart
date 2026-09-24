import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_poc/scoring_poc.dart';
import 'package:sueori/features/reference_landmarks/domain/reference_landmark.dart';
import 'package:sueori/features/scoring/domain/comparison_summary.dart';
import 'package:sueori/features/scoring/domain/hand_track_scoring.dart';
import 'package:sueori/features/scoring/domain/scoring_service.dart';
import 'package:sueori/features/scoring/domain/word_type.dart';

List<Point3> _hand({double shift = 0}) => [
  for (var i = 0; i < 21; i++) Point3(0.5 + i * 0.01 + (i > 4 ? shift : 0), 0.5 + i * 0.02, 0),
];

ReferenceHandFrame _frame(int? tMs) => ReferenceHandFrame(landmarks: _hand(), tMs: tMs);

void main() {
  group('recordingDurationFor', () {
    test('tMs가 없으면 3초', () {
      expect(recordingDurationFor([_frame(null), _frame(null)]), const Duration(seconds: 3));
      expect(recordingDurationFor(const []), const Duration(seconds: 3));
    });

    test('기준 길이 × 1.2', () {
      expect(recordingDurationFor([_frame(1000), _frame(3500)]), const Duration(milliseconds: 3000));
    });

    test('최소 2초, 최대 8초', () {
      expect(recordingDurationFor([_frame(0), _frame(500)]), const Duration(seconds: 2));
      expect(recordingDurationFor([_frame(0), _frame(60000)]), const Duration(seconds: 8));
    });
  });

  group('scoreBestHand', () {
    const service = ScoringService();

    test('양손이 잡히면 더 높은 점수의 손을 쓴다', () {
      final best = scoreBestHand(
        service: service,
        wordType: WordType.staticSign,
        referenceFrames: [_hand()],
        captured: [
          CapturedFrame(tMs: 0, points: _hand(shift: 0.3), handedness: 'Left'),
          CapturedFrame(tMs: 0, points: _hand(), handedness: 'Right'),
        ],
      );
      expect(best!.frames.single.handedness, 'Right');
      expect(best.score, closeTo(100, 0.01));
    });

    test('프레임이 모자란 손과 NaN 좌표 손은 건너뛴다', () {
      final nan = [for (var i = 0; i < 21; i++) Point3(double.nan, 0, 0)];
      final best = scoreBestHand(
        service: service,
        wordType: WordType.dynamicSign,
        referenceFrames: [_hand(), _hand()],
        captured: [
          for (var t = 0; t < 5; t++) CapturedFrame(tMs: t * 100, points: nan, handedness: 'Left'),
          for (var t = 0; t < 5; t++) CapturedFrame(tMs: t * 100, points: _hand(), handedness: 'Right'),
          CapturedFrame(tMs: 0, points: _hand(), handedness: null),
        ],
        minFrames: 5,
      );
      expect(best!.frames.first.handedness, 'Right');
    });

    test('채점 가능한 손이 없으면 null', () {
      expect(
        scoreBestHand(service: service, wordType: WordType.dynamicSign, referenceFrames: [_hand()], captured: const [], minFrames: 5),
        isNull,
      );
    });
  });

  test('comparison_summary는 version 2', () {
    final summary = buildComparisonSummary(
      wordType: WordType.staticSign,
      referenceFrames: [_hand()],
      userFrames: [CapturedFrame(tMs: 0, points: _hand())],
    );
    expect(summary['version'], 2);
  });
}

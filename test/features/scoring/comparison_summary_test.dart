import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_poc/scoring_poc.dart';
import 'package:sueori/features/scoring/domain/comparison_summary.dart';
import 'package:sueori/features/scoring/domain/word_type.dart';

List<Point3> _hand({double fingerShift = 0}) => [
  for (var i = 0; i < 21; i++) Point3(0.5 + i * 0.01 + (i == 8 ? fingerShift : 0), 0.5 + i * 0.02, 0),
];

void main() {
  test('정적: DB CHECK 필수 키와 21개 배열, 가장 어긋난 관절을 담는다', () {
    final summary = buildComparisonSummary(
      wordType: WordType.staticSign,
      referenceFrames: [_hand()],
      userFrames: [CapturedFrame(tMs: 0, points: _hand(fingerShift: 0.1), handedness: 'Right')],
    );

    expect(summary.keys, containsAll(['version', 'algorithm', 'landmarkDeltas']));
    expect(summary['algorithm'], 'distance');
    expect(summary['handedness'], 'right');
    expect(summary['userLandmarks'], hasLength(21));
    expect((summary['userLandmarks'] as List).first, [0.0, 0.0, 0.0]);
    expect(summary['landmarkDeltas'], hasLength(21));
    expect((summary['weakestLandmarks'] as List).first, 8);
  });

  test('동적: 오차가 가장 큰 순간의 프레임 쌍을 대표로 기록한다', () {
    final summary = buildComparisonSummary(
      wordType: WordType.dynamicSign,
      referenceFrames: [_hand(), _hand(), _hand()],
      userFrames: [
        CapturedFrame(tMs: 0, points: _hand()),
        CapturedFrame(tMs: 100, points: _hand()),
        CapturedFrame(tMs: 200, points: _hand()),
        CapturedFrame(tMs: 300, points: _hand(fingerShift: 0.2)),
      ],
    );

    expect(summary['algorithm'], 'dtw');
    expect(summary['userTimestampMs'], 300);
    expect(summary['referenceFrameIndex'], 2);
  });
}

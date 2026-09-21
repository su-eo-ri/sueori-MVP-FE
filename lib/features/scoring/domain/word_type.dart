/// 수어 단어의 채점 방식 분기 기준. Supabase `Word.type` 컬럼('static'|'dynamic')에 대응.
enum WordType {
  /// 정적 수어(지문자) — 프레임 1개, [DistanceScorer]로 채점.
  staticSign,

  /// 동적 수어(단어) — 프레임 시퀀스, [DtwScorer]로 채점.
  dynamicSign;

  static WordType fromDbValue(String value) => switch (value) {
    'static' => WordType.staticSign,
    'dynamic' => WordType.dynamicSign,
    _ => throw ArgumentError('알 수 없는 Word.type 값: $value'),
  };
}

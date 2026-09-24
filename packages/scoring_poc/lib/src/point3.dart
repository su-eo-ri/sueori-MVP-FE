/// MediaPipe HandLandmarker가 내놓는 랜드마크 1개 점.
/// x, y는 정규화 이미지 좌표(0~1), z는 손목 기준 상대 깊이(카메라와의 거리와 무관한 스케일).
class Point3 {
  final double x;
  final double y;
  final double z;

  const Point3(this.x, this.y, this.z);
}

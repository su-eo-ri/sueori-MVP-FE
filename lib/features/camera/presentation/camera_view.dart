// 카메라 미리보기용 HTML video/canvas를 Flutter Web의 PlatformView로 등록.
// poc/hand_landmark_poc과 동일한 패턴 — registerCameraView()는 runApp() 전에
// main()에서 한 번만 호출해야 한다.

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const cameraVideoElementId = 'sueori-video';
const cameraCanvasElementId = 'sueori-canvas';
const _viewType = 'sueori-camera-view';

void registerCameraView() {
  ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
    final container = web.HTMLDivElement()
      ..style.position = 'relative'
      ..style.width = '480px'
      ..style.height = '360px'
      ..style.backgroundColor = '#111';

    final video = web.HTMLVideoElement()
      ..id = cameraVideoElementId
      ..autoplay = true
      ..muted = true
      ..style.position = 'absolute'
      ..style.left = '0'
      ..style.top = '0'
      ..style.width = '480px'
      ..style.height = '360px'
      ..style.transform = 'scaleX(-1)' // 거울모드
      ..setAttribute('playsinline', 'true');

    final canvas = web.HTMLCanvasElement()
      ..id = cameraCanvasElementId
      ..width = 480
      ..height = 360
      ..style.position = 'absolute'
      ..style.left = '0'
      ..style.top = '0'
      ..style.width = '480px'
      ..style.height = '360px'
      ..style.transform = 'scaleX(-1)';

    container.append(video);
    container.append(canvas);
    return container;
  });
}

/// 카메라 프리뷰 + 스켈레톤 오버레이(그리기는 JS 쪽 담당).
class CameraPreview extends StatelessWidget {
  const CameraPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 480, height: 360, child: HtmlElementView(viewType: _viewType));
  }
}

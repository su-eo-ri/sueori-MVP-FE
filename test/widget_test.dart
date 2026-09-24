// 스모크 테스트: 앱이 크래시 없이 첫 프레임을 그리는지만 확인.
// Supabase.initialize()는 네트워크 I/O라 위젯 테스트 범위 밖이므로, currentUserProvider를
// override해서 실제 Supabase 클라이언트를 건드리지 않고 라우팅/렌더링만 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sueori/core/router/app_router.dart';
import 'package:sueori/features/auth/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('앱이 크래시 없이 첫 프레임을 렌더링한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('수어리'), findsOneWidget);
  });
}

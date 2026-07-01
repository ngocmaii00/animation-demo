import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:love_alarm_motion_lab/main.dart';

void main() {
  testWidgets('Love Alarm Motion Lab renders the presentation shell', (
    tester,
  ) async {
    await tester.pumpWidget(const LoveAlarmMotionLabApp());

    expect(find.text('Love Alarm Motion Lab'), findsWidgets);
    expect(find.text('Interactive presentation app'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Disabling a required widget breaks the live preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LoveAlarmMotionLabApp());
    await tester.pump();

    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Live Preview Build Failed'), findsOneWidget);
    expect(find.textContaining('MissingDependencyError'), findsWidgets);
  });

  testWidgets('Editing code updates the live preview overlay', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LoveAlarmMotionLabApp());
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, r'''Text('Live Edited')
  .animate()
  .fadeIn(duration: 450.ms)''');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Live Edited'), findsWidgets);
    expect(find.textContaining('duration 450ms'), findsOneWidget);
  });

  testWidgets(
    'AnimatedScale live code renders scale and reports invalid code',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const LoveAlarmMotionLabApp());
      await tester.pump();

      await tester.tap(find.text('Next').last);
      await tester.pump(const Duration(milliseconds: 700));

      await tester.enterText(find.byType(TextField).first, r'''AnimatedScale(
  duration: const Duration(milliseconds: 700),
  curve: Curves.easeOutBack,
  scale: active ? 2 : 0,
  child: const Icon(Icons.favorite),
)''');
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.textContaining('duration 700ms'), findsOneWidget);
      expect(find.textContaining('scale: 0.00 -> 2.00'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, r'''AnimatedScale(
  duration: const Duration(milliseconds: 700),
  child: const Icon(Icons.favorite),
)''');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Live Code Rebuild Failed'), findsOneWidget);
      expect(
        find.textContaining('AnimatedScale code must include scale'),
        findsWidgets,
      );
    },
  );
}

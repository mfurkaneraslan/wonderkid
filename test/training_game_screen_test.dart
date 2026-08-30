import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/training/training_game_screen.dart';

Future<List<Offset>> _passingPatternCenters(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2100));
  await tester.pump();
  final centers = <Offset>[];
  for (var step = 0; step < 9; step++) {
    final finder = find.byKey(Key('passingPatternStep$step'));
    if (finder.evaluate().isEmpty) break;
    centers.add(tester.getCenter(finder));
  }
  return centers;
}

Future<void> _drawPassingPattern(
  WidgetTester tester,
  List<Offset> centers,
) async {
  final gesture = await tester.startGesture(centers.first);
  for (final center in centers.skip(1)) {
    await gesture.moveTo(center);
    await tester.pump(const Duration(milliseconds: 40));
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('every attribute opens its own training game', (tester) async {
    for (final attribute in TrainingAttribute.values) {
      await tester.pumpWidget(
        MaterialApp(home: TrainingGameScreen(attribute: attribute)),
      );

      expect(find.byKey(const Key('trainingGameScreen')), findsOneWidget);
      if (attribute == TrainingAttribute.passing) {
        expect(find.byKey(const Key('passingStatus')), findsOneWidget);
        expect(find.byKey(const Key('trainingTimer')), findsNothing);
        expect(find.text('20 sn'), findsNothing);
      } else {
        expect(find.byKey(const Key('trainingTimer')), findsOneWidget);
        expect(find.text('20 sn'), findsOneWidget);
      }
      expect(find.byKey(const Key('trainingLives')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets(
    'training finishes successfully when the 20 second timer expires',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrainingGameScreen(attribute: TrainingAttribute.shooting),
        ),
      );

      await tester.pump(const Duration(seconds: 20));
      await tester.pump();

      expect(find.byKey(const Key('trainingResult')), findsOneWidget);
      expect(find.text('ANTRENMAN TAMAMLANDI'), findsOneWidget);
      expect(find.byKey(const Key('retryTrainingButton')), findsOneWidget);
      expect(find.byKey(const Key('finishTrainingButton')), findsOneWidget);
      expect(find.text('Başarılı antrenman!'), findsOneWidget);
    },
  );

  testWidgets('successful training shows the tiered stat reward', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(
          attribute: TrainingAttribute.pace,
          statIncrease: 0.5,
        ),
      ),
    );

    for (var index = 0; index < 200; index++) {
      final activeTarget = find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'paceActiveTarget',
                ),
          )
          .first;
      await tester.tap(activeTarget);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    expect(find.text('Başarılı antrenman!'), findsOneWidget);
    expect(find.textContaining('Hız +0,5'), findsOneWidget);
  });

  testWidgets('score does not grant a reward when all three lives are lost', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.pace),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('paceTarget'),
      ),
      findsNWidgets(9),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Süre dolmadan 3 hakkın da bitti.'), findsOneWidget);
    expect(find.textContaining('Gelişim kazanamadın'), findsOneWidget);
  });

  testWidgets('pace lights the next target halfway through the window', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.pace),
      ),
    );

    Finder activeTargets() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'paceActiveTarget',
          ),
    );

    expect(activeTargets(), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 360));
    expect(activeTargets(), findsNWidgets(2));
  });

  testWidgets('shooting scores with a balanced upward swipe', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.shooting),
      ),
    );

    expect(find.byKey(const Key('shootingGoal')), findsOneWidget);
    expect(find.byKey(const Key('shootingBall')), findsOneWidget);
    final swipeArea = find.byKey(const Key('shootingSwipeArea'));
    await tester.fling(swipeArea, const Offset(0, -180), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    final feedback = find.byKey(const Key('shotFeedback'));
    expect(feedback, findsOneWidget);
    expect(tester.widget<Text>(feedback).data, 'GOL!');
  });

  testWidgets('shooting rejects weak and overpowered swipes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.shooting),
      ),
    );

    final swipeArea = find.byKey(const Key('shootingSwipeArea'));
    await tester.fling(swipeArea, const Offset(0, -100), 350);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('ÇOK ZAYIF'), findsOneWidget);

    await tester.fling(swipeArea, const Offset(0, -240), 2400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('FAZLA GÜÇLÜ'), findsOneWidget);
  });

  testWidgets('shooting cannot be tuned by holding a long drag', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.shooting),
      ),
    );

    final swipeArea = find.byKey(const Key('shootingSwipeArea'));
    await tester.timedDrag(
      swipeArea,
      const Offset(0, -260),
      const Duration(milliseconds: 900),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ÇOK ZAYIF'), findsOneWidget);
  });

  testWidgets('shooting follows the swipe angle and can miss wide', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.shooting),
      ),
    );

    final swipeArea = find.byKey(const Key('shootingSwipeArea'));

    await tester.fling(swipeArea, const Offset(-70, -200), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    final angledFeedback = tester.widget<Text>(
      find.byKey(const Key('shotFeedback')),
    );
    expect(angledFeedback.data, 'GOL!');

    await tester.fling(swipeArea, const Offset(180, -200), 1400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('DIŞARI'), findsOneWidget);
  });

  testWidgets('passing has no timer and completes after four patterns', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.passing),
      ),
    );

    expect(find.text('DESENİ İZLE'), findsOneWidget);
    expect(find.byKey(const Key('trainingTimer')), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(find.byKey(const Key('trainingResult')), findsNothing);
    expect(find.text('SIRA SENDE'), findsOneWidget);

    for (var round = 0; round < 4; round++) {
      final centers = await _passingPatternCenters(tester);
      expect(centers.length, inInclusiveRange(5, 9));
      expect(find.text('SIRA SENDE'), findsOneWidget);
      await _drawPassingPattern(tester, centers);
    }

    expect(find.byKey(const Key('trainingResult')), findsOneWidget);
    expect(find.text('Başarılı antrenman!'), findsOneWidget);
    expect(find.textContaining('4 doğru hamle'), findsOneWidget);
  });

  testWidgets('passing loses a life for an incomplete pattern', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.passing),
      ),
    );

    for (var attempt = 0; attempt < 3; attempt++) {
      final centers = await _passingPatternCenters(tester);
      await _drawPassingPattern(tester, centers.take(2).toList());
    }

    expect(find.byKey(const Key('trainingResult')), findsOneWidget);
    expect(find.text('3 hakkın da bitti.'), findsOneWidget);
    expect(find.textContaining('Gelişim kazanamadın'), findsOneWidget);
  });

  testWidgets('physical training uses left and right balance controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.physical),
      ),
    );

    final board = find.byKey(const Key('physicalBalanceBoard'));
    final indicator = find.byKey(const Key('physicalIndicator'));
    final left = find.byKey(const Key('physicalLeftButton'));
    final right = find.byKey(const Key('physicalRightButton'));
    expect(board, findsOneWidget);
    expect(indicator, findsOneWidget);
    expect(left, findsOneWidget);
    expect(right, findsOneWidget);
    expect(find.byKey(const Key('physicalStopButton')), findsNothing);

    final initialPosition = tester.getCenter(indicator).dx;
    final leftGesture = await tester.startGesture(tester.getCenter(left));
    await tester.pump(const Duration(milliseconds: 220));
    await leftGesture.up();
    await tester.pump();
    expect(tester.getCenter(indicator).dx, isNot(initialPosition));

    final rightGesture = await tester.startGesture(tester.getCenter(right));
    await tester.pump(const Duration(milliseconds: 220));
    await rightGesture.up();
    await tester.pump();
    expect(find.byKey(const Key('trainingGameScreen')), findsOneWidget);
  });

  testWidgets('physical balance fails without player input', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.physical),
      ),
    );

    await tester.pump(const Duration(seconds: 20));
    await tester.pump();

    expect(find.byKey(const Key('trainingResult')), findsOneWidget);
    expect(find.textContaining('Gelişim kazanamadın'), findsOneWidget);
  });

  testWidgets('dribbling player follows horizontal drag without lane taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.dribbling),
      ),
    );

    final player = find.byKey(const Key('dribblingPlayer'));
    final before = tester.getCenter(player).dx;
    await tester.drag(
      find.byKey(const Key('dribblingDragArea')),
      const Offset(90, 0),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final after = tester.getCenter(player).dx;

    expect(after, greaterThan(before));
    expect(find.byKey(const Key('dribblingLane0')), findsNothing);
  });
}

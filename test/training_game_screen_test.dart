import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/training/training_game_screen.dart';

void main() {
  testWidgets('every attribute opens its own 20 second training game', (
    tester,
  ) async {
    for (final attribute in TrainingAttribute.values) {
      await tester.pumpWidget(
        MaterialApp(home: TrainingGameScreen(attribute: attribute)),
      );

      expect(find.byKey(const Key('trainingGameScreen')), findsOneWidget);
      expect(find.byKey(const Key('trainingTimer')), findsOneWidget);
      expect(find.text('20 sn'), findsOneWidget);
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

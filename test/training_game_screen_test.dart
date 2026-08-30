import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/training/training_game_screen.dart';

void main() {
  testWidgets('every attribute opens its own 15 second training game', (
    tester,
  ) async {
    for (final attribute in TrainingAttribute.values) {
      await tester.pumpWidget(
        MaterialApp(home: TrainingGameScreen(attribute: attribute)),
      );

      expect(find.byKey(const Key('trainingGameScreen')), findsOneWidget);
      expect(find.byKey(const Key('trainingTimer')), findsOneWidget);
      expect(find.text('15 sn'), findsOneWidget);
      expect(find.byKey(const Key('trainingLives')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('training finishes when the 15 second timer expires', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrainingGameScreen(attribute: TrainingAttribute.shooting),
      ),
    );

    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.byKey(const Key('trainingResult')), findsOneWidget);
    expect(find.text('ANTRENMAN TAMAMLANDI'), findsOneWidget);
    expect(find.byKey(const Key('retryTrainingButton')), findsOneWidget);
    expect(find.byKey(const Key('finishTrainingButton')), findsOneWidget);
  });

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

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const Key('paceLeftButton')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('paceRightButton')));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.text('Başarılı antrenman!'), findsOneWidget);
    expect(find.textContaining('Hız +0,5'), findsOneWidget);
  });
}

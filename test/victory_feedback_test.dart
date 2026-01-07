import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/feedback_preferences.dart';
import 'package:flutter_application_1/services/feedback_manager.dart';
import 'package:flutter_application_1/services/victory_gate.dart';
import 'package:flutter_application_1/widgets/victory_overlay.dart';

void main() {
  test('victory gate allows only one trigger per execution', () {
    final gate = VictoryGate();

    expect(gate.tryOpen(), isTrue);
    expect(gate.tryOpen(), isFalse);

    gate.reset();
    expect(gate.tryOpen(), isTrue);
  });

  test('feedback manager respects sound toggle', () async {
    var playSoundCalls = 0;
    final manager = FeedbackManager(onPlaySound: () async {
      playSoundCalls += 1;
    });

    await manager.triggerVictoryFeedback(
      const FeedbackPreferences(
        soundEnabled: false,
        animationsEnabled: true,
        hapticEnabled: true,
      ),
    );

    expect(playSoundCalls, 0);
  });

  testWidgets('victory overlay does not crash after unmount',
      (tester) async {
    var dismissCalls = 0;
    final overlay = VictoryOverlay(
      message: 'Parabéns!',
      preferences: FeedbackPreferences.defaults(),
      feedbackManager: const FeedbackManager(),
      displayDuration: const Duration(milliseconds: 10),
      onDismiss: () {
        dismissCalls += 1;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: overlay),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));

    expect(tester.takeException(), isNull);
    expect(dismissCalls, 0);
  });
}

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/controllers/routine_run_timer_controller.dart';

void main() {
  test('startStep inicia e remaining diminui', () {
    final controller = RoutineRunTimerController();

    fakeAsync((async) {
      controller.startStep(0, 3);

      expect(controller.status, RoutineRunTimerStatus.running);
      expect(controller.remaining, const Duration(seconds: 3));

      async.elapse(const Duration(seconds: 1));

      expect(controller.remaining, const Duration(seconds: 2));
      expect(controller.status, RoutineRunTimerStatus.running);
    });

    controller.dispose();
  });

  test('startStep em novo passo reseta remaining e continua rodando', () {
    final controller = RoutineRunTimerController();

    fakeAsync((async) {
      controller.startStep(0, 5);
      async.elapse(const Duration(seconds: 2));

      expect(controller.remaining, const Duration(seconds: 3));

      controller.startStep(1, 10);

      expect(controller.currentStepIndex, 1);
      expect(controller.remaining, const Duration(seconds: 10));
      expect(controller.status, RoutineRunTimerStatus.running);

      async.elapse(const Duration(seconds: 1));

      expect(controller.remaining, const Duration(seconds: 9));
      expect(controller.status, RoutineRunTimerStatus.running);
    });

    controller.dispose();
  });

  test('dispose cancela timer e evita callback após descarte', () {
    var callbackCalls = 0;
    final controller = RoutineRunTimerController(
      onStepCompleted: () async {
        callbackCalls += 1;
      },
    );

    fakeAsync((async) {
      controller.startStep(0, 1);
      controller.dispose();

      async.elapse(const Duration(seconds: 2));

      expect(callbackCalls, 0);
    });
  });

  test('pause mantém remaining e resume continua contagem', () {
    final controller = RoutineRunTimerController();

    fakeAsync((async) {
      controller.startStep(0, 4);
      async.elapse(const Duration(seconds: 2));

      expect(controller.remaining, const Duration(seconds: 2));
      controller.pause();
      expect(controller.status, RoutineRunTimerStatus.paused);

      async.elapse(const Duration(seconds: 2));
      expect(controller.remaining, const Duration(seconds: 2));

      controller.resume();
      expect(controller.status, RoutineRunTimerStatus.running);

      async.elapse(const Duration(seconds: 1));
      expect(controller.remaining, const Duration(seconds: 1));
    });

    controller.dispose();
  });
}

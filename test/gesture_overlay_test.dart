import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donghua_player/features/player/widgets/gesture_overlay.dart';

void main() {
  testWidgets('player controls receive taps above the gesture layer', (
    tester,
  ) async {
    var buttonTapped = false;
    var controlsToggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureOverlay(
            onToggleControls: () => controlsToggled = true,
            onDoubleTapLeft: () {},
            onDoubleTapRight: () {},
            child: Center(
              child: ElevatedButton(
                onPressed: () => buttonTapped = true,
                child: const Text('Play'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pump();

    expect(buttonTapped, isTrue);
    expect(controlsToggled, isFalse);
  });
}

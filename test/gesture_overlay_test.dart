import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donghua_player/features/player/widgets/gesture_overlay.dart';

void main() {
  testWidgets('controls above the gesture layer receive taps', (tester) async {
    var buttonTapped = false;
    var controlsToggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Gesture layer sits under interactive controls, the same way
              // it sits under PlayerControls in PlayerScreen.build.
              GestureOverlay(
                onToggleControls: () => controlsToggled = true,
                onDoubleTapLeft: () {},
                onDoubleTapRight: () {},
                // The video surface: no tap handler of its own.
                child: Container(color: Colors.black),
              ),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => buttonTapped = true,
                  child: const Text('Play'),
                ),
              ),
            ],
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

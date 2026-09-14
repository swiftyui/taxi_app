import 'package:TaxiApp/src/core/widgets/pickers/hambago_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HambaGo time picker returns the selected initial time', (
    tester,
  ) async {
    TimeOfDay? selectedTime;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selectedTime = await showHambaGoTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 11, minute: 33),
                );
              },
              child: const Text('Choose time'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose time'));
    await tester.pumpAndSettle();

    expect(find.text('Departure time'), findsOneWidget);
    expect(find.text('11:33'), findsOneWidget);
    expect(find.text('Use this time'), findsOneWidget);

    await tester.tap(find.text('Use this time'));
    await tester.pumpAndSettle();

    expect(selectedTime, const TimeOfDay(hour: 11, minute: 33));
  });
}

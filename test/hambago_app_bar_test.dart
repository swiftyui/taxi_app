import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HambaGo app bar uses a compact back control', (tester) async {
    var didGoBack = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: HambaGoAppBar(
            title: 'Driver account',
            subtitle: 'Manage your HambaGo taxi',
            onBackPressed: () => didGoBack = true,
          ),
        ),
      ),
    );

    expect(find.text('Driver account'), findsOneWidget);
    expect(find.text('Manage your HambaGo taxi'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('Back')), const Size(40, 40));

    await tester.tap(find.byTooltip('Back'));
    expect(didGoBack, isTrue);
  });
}

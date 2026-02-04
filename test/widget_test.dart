import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rimun_app/main.dart';

void main() {
  testWidgets('Login flow shows Home with navigation', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MUNApp());

    // Verify login screen is visible
    expect(find.text('RIMUN APP'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Enter demo credentials (debug-only flow)
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'demo@rimun.it',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      '123',
    );
    await tester.tap(find.text('Login'));

    // Let navigation complete
    await tester.pumpAndSettle();

    // Verify HomeScreen is shown (AppBar title 'RIMUN' and nav labels)
    expect(find.text('RIMUN'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

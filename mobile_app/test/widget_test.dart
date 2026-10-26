import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrack/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartTrackApp(loggedIn: false));
    expect(find.textContaining('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}

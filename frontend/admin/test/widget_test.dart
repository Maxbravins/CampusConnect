import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/screens/welcome_screen.dart';

void main() {
  testWidgets('CampusConnect admin welcome screen loads',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.text('CampusConnect Admin'), findsOneWidget);
    expect(find.text('Log In to Admin Portal'), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/welcome_screen.dart';

void main() {
  testWidgets('CampusConnect welcome screen loads',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.text('CampusConnect'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
  });
}
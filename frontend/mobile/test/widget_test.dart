import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('CampusConnect mobile app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusConnectApp());

    expect(find.text('CampusConnect'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kios_aisyha/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KiosAisyhaApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

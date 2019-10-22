import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:spoiler/spoilers.dart';

void main() {
  group('Spoilers wiget', () {
    testWidgets('can show header', (WidgetTester tester) async {
      final widget = Spoilers();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.byKey(Key('header')), findsOneWidget);
    });

    testWidgets('can show custom header', (WidgetTester tester) async {
      final widget = Spoilers(header: Text("test header name"));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.text('test header name'), findsOneWidget);
    });

    testWidgets('can show and hide content', (WidgetTester tester) async {});
  });
}

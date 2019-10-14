import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spoiler/spoiler.dart';

void main() {
  group('Spoiler wiget', () {
    testWidgets('can show header', (WidgetTester tester) async {
      final widget = Spoiler();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.byKey(Key('header')), findsOneWidget);
    });

    testWidgets('can show custom header', (WidgetTester tester) async {
      final widget = Spoiler(header: Text("test header name"));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.text('test header name'), findsOneWidget);
    });

    testWidgets('can show and hide content', (WidgetTester tester) async {
      final widget = Spoiler(child: Text('context'));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      final SpoilerState state = tester.state(find.byWidget(widget));

      expect(state.isOpened, isFalse);

      expect(find.byKey(Key('child_closed')), findsOneWidget);
      expect(find.byKey(Key('child_opened')), findsNothing);

      expect(state.animation.value, equals(0));

      await tester.tap(find.byKey(Key('header')));
      await tester.pumpAndSettle();

      expect(state.isOpened, isTrue);

      expect(find.byKey(Key('child_opened')), findsOneWidget);
      expect(find.byKey(Key('child_closed')), findsNothing);

      expect(state.animation.value, isPositive);

      expect(find.text('context'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler/models/spoiler_details.dart';
import 'package:spoiler/spoiler.dart';

void main() {
  group('Spoiler widget', () {
    testWidgets('can show header', (WidgetTester tester) async {
      const testWidget = Spoiler();

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.byKey(const Key('spoiler_header')), findsOneWidget);
    });

    testWidgets('can show custom header', (WidgetTester tester) async {
      const testWidget = Spoiler(
        headerWhenSpoilerClosed: Text(
          "test header name",
        ),
      );

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('test header name'), findsOneWidget);
    });

    testWidgets('can show custom header', (WidgetTester tester) async {
      const testWidget = Spoiler(
        headerWhenSpoilerClosed: Text(
          "test header name when close",
        ),
        headerWhenSpoilerOpened: Text(
          "test header name when open",
        ),
      );

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('test header name when close'), findsOneWidget);

      await tester.tap(find.text('test header name when close'));
      await tester.pumpAndSettle();

      expect(find.text('test header name when close'), findsNothing);
      expect(find.text('test header name when open'), findsOneWidget);
    });

    testWidgets('can show leading arrow', (WidgetTester tester) async {
      const testWidget = Spoiler(
        headerWhenSpoilerClosed: SizedBox(
          width: 10,
        ),
        leadingArrow: true,
      );

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(Icons.keyboard_arrow_down)),
        equals(const Offset(12, 12)),
      );

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });

    testWidgets('can show trailing arrow', (WidgetTester tester) async {
      const testWidget = Spoiler(
        headerWhenSpoilerClosed: SizedBox(width: 10),
        trailingArrow: true,
      );

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(Icons.keyboard_arrow_down)),
        equals(const Offset(22, 12)),
      );

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });

    testWidgets('can show and hide content', (WidgetTester tester) async {
      // It's open first time by default, and after first frame it close.
      const testWidget = Spoiler(
        child: Text(
          'context',
        ),
      );

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      final SpoilerState state = tester.state(find.byWidget(testWidget));

      expect(find.text('context'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(state.isOpened, isFalse);

      expect(find.byKey(const Key('spoiler_child_closed')), findsOneWidget);
      expect(find.byKey(const Key('spoiler_child_opened')), findsNothing);

      expect(state.childHeightAnimation.value, equals(0));

      await tester.tap(find.byKey(const Key('spoiler_header')));
      await tester.pumpAndSettle();

      expect(state.isOpened, isTrue);

      expect(find.byKey(const Key('spoiler_child_closed')), findsNothing);
      expect(find.byKey(const Key('spoiler_child_opened')), findsOneWidget);

      expect(state.childHeightAnimation.value, isPositive);
    });
  });

  group('Spoiler widget callbacks', () {
    testWidgets('can be invoked when widgets ready', (tester) async {
      late SpoilerDetails spoilerDetails;

      final testWidget = Spoiler(
        onReadyCallback: (details) => spoilerDetails = details,
        headerWhenSpoilerClosed: const SizedBox(width: 10, height: 15),
        child: const SizedBox(width: 20, height: 25),
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(spoilerDetails.headerWidth, equals(10));
      expect(spoilerDetails.headerHeight, equals(15));

      expect(spoilerDetails.childWidth, equals(20));
      expect(spoilerDetails.childHeight, equals(25));
    });

    testWidgets('can be send when widgets toggle and height or width change',
        (tester) async {
      late SpoilerDetails spoilerDetails;
      List<SpoilerDetails> details = [];

      final testWidget = Spoiler(
        child: const Text('context'),
        onReadyCallback: (details) => spoilerDetails = details,
        onUpdateCallback: (updatedDetails) => details.add(updatedDetails),
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);
      final SpoilerState state = tester.state(find.byWidget(testWidget));

      expect(spoilerDetails, isNotNull);
      expect(spoilerDetails.isOpened, isFalse);

      expect(state.isOpened, isFalse);

      await tester.tap(find.byKey(const Key('spoiler_header')));
      await tester.pumpAndSettle();

      expect(state.isOpened, isTrue);

      expect(details, isNotEmpty);
      expect(details.last.isOpened, isTrue);
      expect(details.last.childHeight, isPositive);
      expect(spoilerDetails.childHeight == details.last.childHeight, isTrue);

      await tester.tap(find.byKey(const Key('spoiler_header')));
      await tester.pumpAndSettle();

      expect(state.isOpened, false);

      expect(spoilerDetails.childHeight == details.last.childHeight, isFalse);
      expect(details.last.childHeight, equals(0));
    });
  });
}

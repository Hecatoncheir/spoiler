import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:spoiler/spoiler.dart';
import 'package:spoiler/spoilers.dart';
import 'package:spoiler/models/spoilers_details.dart';

void main() {
  group('Spoilers widget', () {
    testWidgets('can show header', (WidgetTester tester) async {
      const testWidget = Spoilers();

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.byKey(const Key('spoilers_header')), findsOneWidget);
    });

    testWidgets('can show custom header', (WidgetTester tester) async {
      const testWidget = Spoilers(
        header: Text(
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

    testWidgets('can show and hide content', (WidgetTester tester) async {
      const testWidget = Spoilers(
        header: Text("test header name"),
        children: [
          Spoiler(
            child: SizedBox(
              width: 20,
              height: 20,
              child: Text(
                'context',
              ),
            ),
          )
        ],
      );

      const widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      final SpoilersState state = tester.state(find.byWidget(testWidget));

      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(state.isOpened, isFalse);

      expect(find.byKey(const Key('spoilers_child_closed')), findsOneWidget);
      expect(find.byKey(const Key('spoilers_child_opened')), findsNothing);

      expect(state.childHeightAnimation.value, equals(0));

      await tester.tap(find.byKey(const Key('spoilers_header')));
      await tester.pumpAndSettle();

      await tester.runAsync(
        () => Future.delayed(
          const Duration(
            milliseconds: 600,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(state.isOpened, isTrue);

      expect(find.byKey(const Key('spoilers_child_opened')), findsOneWidget);
      expect(find.byKey(const Key('spoilers_child_closed')), findsNothing);

      expect(state.childHeightAnimation.value, isPositive);

      expect(find.text('context'), findsOneWidget);
    });
  });

  group('Spoilers widget callbacks', () {
    testWidgets('can be invoked when widgets ready', (tester) async {
      const firstSpoiler = Spoiler(
        isOpened: true,
        header: SizedBox(
          width: 10,
          height: 15,
          child: Text('first spoiler header'),
        ),
        child: SizedBox(
          width: 20,
          height: 25,
          child: Text('first spoiler content'),
        ),
      );

      const secondSpoiler = Spoiler(
        isOpened: true,
        header: SizedBox(
          width: 10,
          height: 15,
          child: Text('second spoiler header'),
        ),
        child: SizedBox(
          width: 20,
          height: 25,
          child: Text('second spoiler content'),
        ),
      );

      late final SpoilersDetails spoilersDetails;

      final widget = Spoilers(
        onReadyCallback: (details) => spoilersDetails = details,
        header: const SizedBox(
          width: 10,
          height: 15,
        ),
        children: const [
          firstSpoiler,
          secondSpoiler,
        ],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      expect(spoilersDetails.headerWidth, equals(10));
      expect(spoilersDetails.headerHeight, equals(15));

      final firstSpoilerDetails = spoilersDetails.spoilersDetails.first.details;

      expect(firstSpoilerDetails!, isNotNull);

      expect(firstSpoilerDetails.headerWidth, equals(10));
      expect(firstSpoilerDetails.headerHeight, equals(15));

      /// Zero because spoiler is not opened (closed) by Spoilers widget.
      expect(firstSpoilerDetails.childHeight, equals(0.0));

      final secondSpoilerDetails = spoilersDetails.spoilersDetails.last.details;

      expect(secondSpoilerDetails!, isNotNull);

      expect(secondSpoilerDetails.headerWidth, equals(10));
      expect(secondSpoilerDetails.headerHeight, equals(15));

      /// Zero because spoiler is not opened (closed) by Spoilers widget.
      expect(secondSpoilerDetails.childHeight, equals(0.0));
    });

    testWidgets('can be invoked when widgets ready', (tester) async {
      const firstSpoiler = Spoiler(
        isOpened: false,
        header: SizedBox(
          width: 10,
          height: 15,
          child: Text('first spoiler header'),
        ),
        child: SizedBox(
          width: 20,
          height: 25,
          child: Text('first spoiler content'),
        ),
      );

      const secondSpoiler = Spoiler(
        isOpened: false,
        header: SizedBox(
          width: 10,
          height: 15,
          child: Text('second spoiler header'),
        ),
        child: SizedBox(
          width: 20,
          height: 25,
          child: Text('second spoiler content'),
        ),
      );

      late final SpoilersDetails spoilersDetails;

      final widget = Spoilers(
        onReadyCallback: (details) => spoilersDetails = details,
        header: const SizedBox(
          width: 10,
          height: 15,
        ),
        children: const [
          firstSpoiler,
          secondSpoiler,
        ],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      expect(spoilersDetails.headerWidth, equals(10));
      expect(spoilersDetails.headerHeight, equals(15));

      final firstSpoilerDetails = spoilersDetails.spoilersDetails.first.details;
      expect(firstSpoilerDetails!, isNotNull);

      expect(firstSpoilerDetails.headerWidth, equals(10));
      expect(firstSpoilerDetails.headerHeight, equals(15));

      /// Zero because spoiler is not opened (closed) by Spoilers widget.
      expect(firstSpoilerDetails.childHeight, equals(0.0));

      final secondSpoilerDetails = spoilersDetails.spoilersDetails.last.details;

      expect(secondSpoilerDetails!, isNotNull);

      expect(secondSpoilerDetails.headerWidth, equals(10));
      expect(secondSpoilerDetails.headerHeight, equals(15));

      /// Zero because spoiler is not opened (closed) by Spoilers widget.
      expect(secondSpoilerDetails.childHeight, equals(0.0));
    });

    testWidgets('can be send when widgets toggle and height or width change',
        (tester) async {
      const firstSpoiler = Spoiler(
        header: SizedBox(
          width: 10,
          height: 15,
          child: Text('first spoiler header'),
        ),
        child: SizedBox(
          width: 20,
          height: 25,
          child: Text('first spoiler content'),
        ),
      );

      const secondSpoiler = Spoiler(
        header: SizedBox(
          width: 10,
          height: 15,
          child: Text('second spoiler header'),
        ),
        child: SizedBox(
          width: 20,
          height: 25,
          child: Text('second spoiler content'),
        ),
      );

      late final SpoilersDetails spoilersDetails;
      late final List<SpoilersDetails> details = [];

      final widget = Spoilers(
        children: const [
          firstSpoiler,
          secondSpoiler,
        ],
        onReadyCallback: (details) => spoilersDetails = details,
        onUpdateCallback: (updatedDetails) => details.add(updatedDetails),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      final SpoilersState state = tester.state(find.byWidget(widget));

      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(spoilersDetails, isNotNull);
      expect(spoilersDetails.isOpened, isFalse);

      expect(state.isOpened, isFalse);

      await tester.tap(find.byKey(const Key('spoilers_header')));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(spoilersDetails.isOpened, isFalse);
      expect(details.last.isOpened, isTrue);

      expect(state.isOpened, isTrue);

      expect(details, isNotEmpty);
      expect(details.last.isOpened, isTrue);
      expect(details.last.childHeight, isPositive);
      expect(details.last.childHeight, equals(30));

      await tester.tap(find.byKey(const Key('spoilers_header')));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(state.isOpened, false);

      expect(spoilersDetails.isOpened, isFalse);
      expect(details.last.isOpened, isFalse);
      expect(spoilersDetails.childHeight != details.last.childHeight, isTrue);
      expect(details.last.childHeight, equals(0));
    });
  });
}

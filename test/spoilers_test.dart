import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spoiler/spoiler.dart';

import 'package:spoiler/spoilers.dart';

void main() {
  group('Spoilers wiget', () {
    testWidgets('can show header', (WidgetTester tester) async {
      final widget = Spoilers();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.byKey(Key('spoilers_header')), findsOneWidget);
    });

    testWidgets('can show custom header', (WidgetTester tester) async {
      final widget = Spoilers(header: Text("test header name"));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.text('test header name'), findsOneWidget);
    });

    testWidgets('can show and hide content', (WidgetTester tester) async {
      final widget = Spoilers(
        header: Text("test header name"),
        children: [
          Spoiler(
              child: SizedBox(width: 20, height: 20, child: Text('context')))
        ],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      final SpoilersState state = tester.state(find.byWidget(widget));

      expect(state.isOpened, isFalse);

      expect(find.byKey(Key('spoilers_child_closed')), findsOneWidget);
      expect(find.byKey(Key('spoilers_child_opened')), findsNothing);

      expect(state.childHeightAnimation.value, equals(0));

      await tester.tap(find.byKey(Key('spoilers_header')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future.delayed(Duration(seconds: 3));
      });

      await tester.pumpAndSettle();
      expect(state.isOpened, isTrue);

      expect(find.byKey(Key('spoilers_child_opened')), findsOneWidget);
      expect(find.byKey(Key('spoilers_child_closed')), findsNothing);

      expect(state.childHeightAnimation.value, isPositive);

      expect(find.text('context'), findsOneWidget);
    });
  });

  group('Spoilers wiget callbacks', () {
    testWidgets('can be invoked when widgets ready', (tester) async {
      final firstSpoiler = Spoiler(
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
          ));

      final secondSpoiler = Spoiler(
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
          ));

      SpoilersDetails spoilersDetails;

      final widget = Spoilers(
          onReadyCallback: (details) => spoilersDetails = details,
          header: SizedBox(width: 10, height: 15),
          children: [firstSpoiler, secondSpoiler]);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      expect(spoilersDetails.headerWidth, equals(10));
      expect(spoilersDetails.headerHeight, equals(15));

      expect(spoilersDetails.headersWidth, equals([10, 10]));
      expect(spoilersDetails.headersHeight, equals([15, 15]));

      expect(spoilersDetails.childrenWidth, equals([20, 20]));
      expect(spoilersDetails.childrenHeight, equals([25, 25]));
    });

    testWidgets('can be invoked when widgets ready', (tester) async {
      final firstSpoiler = Spoiler(
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
          ));

      final secondSpoiler = Spoiler(
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
          ));

      SpoilersDetails spoilersDetails;

      final widget = Spoilers(
          onReadyCallback: (details) => spoilersDetails = details,
          header: SizedBox(width: 10, height: 15),
          children: [firstSpoiler, secondSpoiler]);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      expect(spoilersDetails.headerWidth, equals(10));
      expect(spoilersDetails.headerHeight, equals(15));

      expect(spoilersDetails.headersWidth, equals([10, 10]));
      expect(spoilersDetails.headersHeight, equals([15, 15]));

      expect(spoilersDetails.childrenWidth, equals([]));
      expect(spoilersDetails.childrenHeight, equals([]));
    });

    testWidgets('can be sended when widgets toggle and height or width change',
        (tester) async {
      final firstSpoiler = Spoiler(
          header: SizedBox(
            width: 10,
            height: 15,
            child: Text('first spoiler header'),
          ),
          child: SizedBox(
            width: 20,
            height: 25,
            child: Text('first spoiler content'),
          ));

      final secondSpoiler = Spoiler(
          header: SizedBox(
            width: 10,
            height: 15,
            child: Text('second spoiler header'),
          ),
          child: SizedBox(
            width: 20,
            height: 25,
            child: Text('second spoiler content'),
          ));

      SpoilersDetails spoilersDetails;
      List<SpoilersDetails> details = [];

      final widget = Spoilers(
        children: [firstSpoiler, secondSpoiler],
        onReadyCallback: (details) => spoilersDetails = details,
        onUpdateCallback: (updatedDetails) => details.add(updatedDetails),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      final SpoilersState state = tester.state(find.byWidget(widget));

      expect(spoilersDetails, isNotNull);
      expect(spoilersDetails.isOpened, isFalse);

      expect(state.isOpened, isFalse);

      await tester.tap(find.byKey(Key('spoilers_header')));
      await tester.pumpAndSettle();

      expect(state.isOpened, isTrue);

      expect(details, isNotEmpty);
      expect(details.last.isOpened, isTrue);
      expect(details.last.childHeight, isPositive);
      expect(spoilersDetails.childHeight == details.last.childHeight, isTrue);

      await tester.tap(find.byKey(Key('spoilers_header')));
      await tester.pumpAndSettle();

      expect(state.isOpened, false);

      expect(spoilersDetails.childHeight == details.last.childHeight, isFalse);
      expect(details.last.childHeight, equals(0));
    });
  });
}

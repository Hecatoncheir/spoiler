import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:spoiler/models/spoiler_data.dart';
import 'package:spoiler/models/spoiler_details.dart';
import 'package:spoiler/models/spoilers_details.dart';

import 'spoiler.dart';

typedef OnReady = Function(SpoilersDetails);
typedef OnUpdate = Function(SpoilersDetails);

class Spoilers extends StatefulWidget {
  final Widget? header;
  final List<Spoiler>? children;

  final bool isOpened;

  final Curve openCurve;
  final Curve closeCurve;

  final Duration duration;

  final bool waitCloseAnimationBeforeOpen;

  final OnReady? onReadyCallback;
  final OnUpdate? onUpdateCallback;

  const Spoilers({
    Key? key,
    this.header,
    this.children,
    this.isOpened = false,
    this.waitCloseAnimationBeforeOpen = false,
    this.duration = const Duration(milliseconds: 400),
    this.onReadyCallback,
    this.onUpdateCallback,
    this.openCurve = Curves.easeOutExpo,
    this.closeCurve = Curves.easeInExpo,
  }) : super(key: key);

  @override
  SpoilersState createState() => SpoilersState();
}

class SpoilersState extends State<Spoilers> with TickerProviderStateMixin {
  @visibleForTesting
  late double headerWidth;
  @visibleForTesting
  late double headerHeight;

  @visibleForTesting
  late double childWidth;
  @visibleForTesting
  late double childHeight;

  @visibleForTesting
  late final List<Spoiler> children;
  @visibleForTesting
  late final List<SpoilerData> spoilersChildrenData;
  @visibleForTesting
  late final List<SpoilerDetails> spoilersDetails;

  @visibleForTesting
  late final AnimationController childHeightAnimationController;
  @visibleForTesting
  late Animation<double> childHeightAnimation;

  @visibleForTesting
  late final StreamController<bool> isReadyController;
  @visibleForTesting
  late final Stream<bool> isReady;

  @visibleForTesting
  late final StreamController<bool> isOpenController;
  @visibleForTesting
  late final Stream<bool> isOpen;

  @visibleForTesting
  late bool isOpened;

  @visibleForTesting
  VoidCallback? onUpdateCallbackListener;

  @visibleForTesting
  final GlobalKey headerKey = GlobalKey(debugLabel: 'header');
  @visibleForTesting
  final GlobalKey childKey = GlobalKey(debugLabel: 'child');

  @override
  void initState() {
    super.initState();

    headerWidth = 0;
    headerHeight = 0;

    childWidth = 0;
    childHeight = 0;

    children = <Spoiler>[];
    spoilersChildrenData = <SpoilerData>[];
    spoilersDetails = <SpoilerDetails>[];

    isOpened = widget.isOpened;

    prepareSpoilersAndDetails(widget.children ?? <Spoiler>[]);
    subscribeOnChildrenEvents(spoilersChildrenData);

    isReadyController = StreamController<bool>();
    isReady = isReadyController.stream.asBroadcastStream();

    isOpenController = StreamController<bool>();
    isOpen = isOpenController.stream.asBroadcastStream();

    childHeightAnimationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    childHeightAnimation = CurvedAnimation(
      parent: childHeightAnimationController,
      curve: widget.openCurve,
      reverseCurve: widget.closeCurve,
    );

    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      final headerElement = headerKey.currentContext;
      final childElement = childKey.currentContext;

      if (headerElement == null || childElement == null) return;

      final headerElementSize = headerElement.size;
      final childElementSize = childElement.size;

      if (headerElementSize == null || childElementSize == null) return;

      headerWidth = headerElementSize.width;
      headerHeight = headerElementSize.height;

      childWidth = childElementSize.width;
      childHeight = childElementSize.height;

      await prepareChildrenSize();

      final onUpdateCallback = widget.onUpdateCallback;
      if (onUpdateCallback != null) {
        onUpdateCallbackListener = () {
          onUpdateCallback(
            SpoilersDetails(
              isOpened: isOpened,
              headerWidth: headerWidth,
              headerHeight: headerHeight,
              childWidth: childWidth,
              childHeight: childHeightAnimation.value,
              spoilersDetails: spoilersChildrenData,
            ),
          );
        };

        childHeightAnimation.addListener(onUpdateCallbackListener!);
      }

      final onReadyCallback = widget.onReadyCallback;
      if (onReadyCallback != null) {
        onReadyCallback(
          SpoilersDetails(
            isOpened: isOpened,
            headerWidth: headerWidth,
            headerHeight: headerHeight,
            childWidth: childWidth,
            childHeight: childHeight,
            spoilersDetails: spoilersChildrenData,
          ),
        );
      }

      isReadyController.add(true);

      childHeightAnimation = childHeightAnimation.drive(isOpened
          ? Tween(begin: 0.0, end: getSpoilersHeight())
          : Tween(begin: getSpoilersHeight(), end: 0.0));

      childHeightAnimationController.reset();
      try {
        await childHeightAnimationController.forward().orCancel;
      } on TickerCanceled {
        // the animation got canceled, probably because we were disposed
      }
    });
  }

  @override
  void dispose() {
    if (onUpdateCallbackListener != null) {
      childHeightAnimation.removeListener(onUpdateCallbackListener!);
    }

    childHeightAnimationController.dispose();

    isOpenController.close();
    isReadyController.close();

    for (SpoilerData data in spoilersChildrenData) {
      data.readyEvents?.close();
      data.updateEvents?.close();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: toggle,
          child: Container(
            key: const Key('spoilers_header'),
            child: Container(
              key: headerKey,
              child: widget.header ?? buildDefaultHeader(),
            ),
          ),
        ),
        StreamBuilder<bool>(
          stream: isReady,
          initialData: false,
          builder: (context, snapshot) {
            final isReady = snapshot.data;
            if (isReady == null) return Container();

            if (isReady) {
              return AnimatedBuilder(
                animation: childHeightAnimation,
                builder: (BuildContext context, Widget? child) {
                  return SizedBox(
                    key: isOpened
                        ? const Key('spoilers_child_opened')
                        : const Key('spoilers_child_closed'),
                    height: childHeightAnimation.value > 0
                        ? childHeightAnimation.value
                        : 0,
                    child: Wrap(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children.isNotEmpty
                              ? [for (final spoiler in children) spoiler]
                              : [Container()],
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            if (!isReady) {
              return Container(
                key: isOpened
                    ? const Key('spoilers_child_opened')
                    : const Key('spoilers_child_closed'),
                child: Container(
                  key: childKey,
                  child: Wrap(
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            children.isNotEmpty ? children : [Container()],
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container();
          },
        ),
      ],
    );
  }

  @visibleForTesting
  Future<void> prepareChildDetails(int childIndex) async {
    final spoilerChild = spoilersChildrenData[childIndex];

    final details = await spoilerChild.readyEvents?.stream.first;
    if (details == null) return;

    spoilersDetails.add(details);
    spoilersChildrenData[childIndex].details = details;
  }

  @visibleForTesting
  Future<void> prepareChildrenSize() async {
    final spoilersDetailsQueue = Iterable<Future>.generate(
      spoilersChildrenData.length,
      prepareChildDetails,
    );

    if (spoilersDetailsQueue.isNotEmpty) {
      await Future.wait(spoilersDetailsQueue);
    }

    for (SpoilerDetails details in spoilersDetails) {
      final spoilerIndex = spoilersDetails.indexOf(details);
      final spoilerData = spoilersChildrenData[spoilerIndex].details;

      if (spoilerData == null) continue;

      spoilerData.headerWidth = details.headerWidth;
      spoilerData.headerHeight = details.headerHeight;

      spoilerData.childWidth = details.childWidth;
      spoilerData.childHeight = details.isOpened ? details.childHeight : 0.0;
    }
  }

  @visibleForTesting
  void subscribeOnChildrenEvents(List<SpoilerData> spoilersData) {
    for (SpoilerData spoilerData in spoilersData) {
      final childrenUpdateEvents = spoilerData.updateEvents;

      childrenUpdateEvents?.stream.listen((details) {
        spoilerData.details = details;

        final spoilersHeight =
            getSpoilersHeaderHeight() + getSpoilersChildHeight();

        childHeightAnimation = childHeightAnimation
            .drive(Tween(begin: spoilersHeight, end: spoilersHeight));

        childHeightAnimationController.reset();
      });
    }
  }

  @visibleForTesting
  void prepareSpoilersAndDetails(List<Spoiler> spoilers) {
    for (Spoiler spoiler in spoilers) {
      final detailsReadyController = StreamController<SpoilerDetails>();
      final detailsUpdateController = StreamController<SpoilerDetails>();

      final key = GlobalKey();

      final data = SpoilerData(
        key: key,
        readyEvents: detailsReadyController,
        updateEvents: detailsUpdateController,
        isOpened: spoiler.isOpened,
      );

      spoilersChildrenData.add(data);

      onReadyCallback(SpoilerDetails details) {
        final spoilerOnReadyCallback = spoiler.onReadyCallback;
        if (spoilerOnReadyCallback != null) spoilerOnReadyCallback(details);
        detailsReadyController.add(details);
      }

      onUpdateCallback(SpoilerDetails details) {
        final spoilerOnUpdateCallback = spoiler.onUpdateCallback;
        if (spoilerOnUpdateCallback != null) spoilerOnUpdateCallback(details);
        detailsUpdateController.add(details);
      }

      final updatedSpoiler = Spoiler(
        key: key,
        onReadyCallback: onReadyCallback,
        onUpdateCallback: onUpdateCallback,
        header: spoiler.header,
        child: spoiler.child,
        duration: spoiler.duration,
        isOpened: isOpened ? spoiler.isOpened : false, // need issue
        openCurve: spoiler.openCurve,
        closeCurve: spoiler.closeCurve,
        waitCloseAnimationBeforeOpen: spoiler.waitCloseAnimationBeforeOpen,
      );

      children.add(updatedSpoiler);
    }
  }

  @visibleForTesting
  Future<void> toggle() async {
    try {
      isOpened = isOpened ? false : true;

      isOpenController.add(isOpened);

      final openTween = Tween(begin: 0.0, end: getSpoilersHeight());
      final closeTween = Tween(begin: getSpoilersHeight(), end: 0.0);
      childHeightAnimation = CurvedAnimation(
        parent: childHeightAnimationController,
        curve: widget.openCurve,
        reverseCurve: widget.closeCurve,
      ).drive(isOpened ? openTween : closeTween);

      childHeightAnimationController.reset();

      await childHeightAnimationController.forward().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  @visibleForTesting
  double getSpoilersHeaderHeight() {
    double height = 0.0;

    for (SpoilerData data in spoilersChildrenData) {
      final details = data.details;
      if (details == null) continue;
      height += details.headerHeight;
    }

    return height.toDouble();
  }

  @visibleForTesting
  double getSpoilersHeaderWidth() {
    double width = 0.0;

    for (SpoilerData data in spoilersChildrenData) {
      final details = data.details;
      if (details == null) continue;
      width += details.headerWidth;
    }

    return width.toDouble();
  }

  @visibleForTesting
  double getSpoilersChildHeight() {
    double height = 0.0;

    for (SpoilerData data in spoilersChildrenData) {
      final details = data.details;
      if (details == null) continue;
      height += details.childHeight;
    }

    return height.toDouble();
  }

  @visibleForTesting
  double getSpoilersHeight() =>
      getSpoilersHeaderHeight() + getSpoilersChildHeight();

  @visibleForTesting
  Widget buildDefaultHeader() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: StreamBuilder<bool>(
          stream: isOpen,
          initialData: isOpened,
          builder: (context, snapshot) {
            final isOpened = snapshot.data;
            if (isOpened == null) return Container();

            return isOpened ? const Text('-') : const Text('+');
          },
        ),
      ),
    );
  }
}

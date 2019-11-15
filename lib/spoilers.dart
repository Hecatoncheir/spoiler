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
  final Widget header;
  final List<Spoiler> children;

  final bool isOpened;

  final Curve openCurve;
  final Curve closeCurve;

  final Duration duration;

  final bool waitFirstCloseAnimationBeforeOpen;

  final OnReady onReadyCallback;
  final OnUpdate onUpdateCallback;

  const Spoilers(
      {this.header,
      this.children,
      this.isOpened = false,
      this.waitFirstCloseAnimationBeforeOpen = false,
      this.duration,
      this.onReadyCallback,
      this.onUpdateCallback,
      this.openCurve = Curves.easeOutExpo,
      this.closeCurve = Curves.easeInExpo});

  @override
  SpoilersState createState() => SpoilersState();
}

class SpoilersState extends State<Spoilers> with TickerProviderStateMixin {
  double headerWidth = 0;
  double headerHeight = 0;

  double childWidth = 0;
  double childHeight = 0;

  final List<Spoiler> children = [];
  final List<SpoilerData> spoilersChildrenData = [];

  AnimationController childHeightAnimationController;
  Animation<double> childHeightAnimation;

  StreamController<bool> isReadyController = StreamController();
  Stream<bool> isReady;

  StreamController<bool> isOpenController = StreamController();
  Stream<bool> isOpen;

  bool isOpened;

  @override
  void initState() {
    super.initState();

    isOpened = widget.isOpened;

    prepareSpoilersAndDetails(widget.children == null ? [] : widget.children);
    subscribeOnChildrenEvents(spoilersChildrenData);

    isReady = isReadyController.stream.asBroadcastStream();
    isOpen = isOpenController.stream.asBroadcastStream();

    childHeightAnimationController = AnimationController(
        duration: widget.duration != null
            ? widget.duration
            : Duration(milliseconds: 400),
        vsync: this);

    childHeightAnimation = CurvedAnimation(
        parent: childHeightAnimationController,
        curve: widget.openCurve,
        reverseCurve: widget.closeCurve);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      headerWidth = _headerKey.currentContext.size.width;
      headerHeight = _headerKey.currentContext.size.height;

      childWidth = _childKey.currentContext.size.width;
      childHeight = _childKey.currentContext.size.height;

      await prepareChildrenSize();

      prepareFirstAnimation().then((_) => updateCallbacks());
    });
  }

  Future<void> prepareChildrenSize() async {
    final spoilersSize = <SpoilerDetails>[];

    final spoilersDetailsQueue =
        Iterable<Future>.generate(spoilersChildrenData.length, (index) async {
      final details =
          await spoilersChildrenData[index].readyEvents.stream.first;

      spoilersSize.add(details);
      spoilersChildrenData[index].details = details;
    });

    if (spoilersDetailsQueue.isNotEmpty) {
      await Future.wait(spoilersDetailsQueue);
    }

    for (SpoilerDetails details in spoilersSize) {
      final spoilerIndex = spoilersSize.indexOf(details);
      final spoilerDetails = spoilersChildrenData[spoilerIndex].details;

      spoilerDetails.headerWidth = details.headerWidth;
      spoilerDetails.headerHeight = details.headerHeight;

      spoilerDetails.childWidth = details.childWidth;
      spoilerDetails.childHeight = details.isOpened ? details.childHeight : 0.0;
    }
  }

  void subscribeOnChildrenEvents(List<SpoilerData> spoilersData) {
    for (SpoilerData spoilerData in spoilersData) {
      // ignore: close_sinks
      final childrenUpdateEvents = spoilerData.updateEvents;

      childrenUpdateEvents.stream.listen((details) {
        spoilerData.details = details;

        final spoilersHeight =
            getSpoilersHeaderHeight() + getSpoilersChildHeight();

        childHeightAnimation = childHeightAnimation
            .drive(Tween(begin: spoilersHeight, end: spoilersHeight));

        childHeightAnimationController.reset();
      });
    }
  }

  void updateCallbacks() {
    if (widget.onUpdateCallback != null) {
      childHeightAnimation.addListener(() => widget.onUpdateCallback(
          SpoilersDetails(
              isOpened: isOpened,
              headerWidth: headerWidth,
              headerHeight: headerHeight,
              childWidth: childWidth,
              childHeight: childHeightAnimation.value,
              spoilersDetails: spoilersChildrenData)));
    }

    if (widget.onReadyCallback != null) {
      widget.onReadyCallback(SpoilersDetails(
          isOpened: isOpened,
          headerWidth: headerWidth,
          headerHeight: headerHeight,
          childWidth: childWidth,
          childHeight: childHeight,
          spoilersDetails: spoilersChildrenData));
    }
  }

  Future<void> prepareFirstAnimation() async {
    isReadyController.add(true);

    childHeightAnimation = childHeightAnimation.drive(isOpened
        ? Tween(begin: 0.0, end: getSpoilersHeight())
        : Tween(begin: getSpoilersHeight(), end: 0.0));

    childHeightAnimationController.reset();
    try {
      await childHeightAnimationController.forward().orCancel;
    } on TickerCanceled {}
  }

  @override
  void dispose() {
    childHeightAnimationController.dispose();
    isOpenController.close();
    isReadyController.close();

    for (SpoilerData data in spoilersChildrenData) {
      data.readyEvents.close();
      data.updateEvents.close();
    }

    super.dispose();
  }

  void prepareSpoilersAndDetails(List<Spoiler> spoilers) {
    for (Spoiler spoiler in spoilers) {
      // ignore: close_sinks
      final detailsReadyController = StreamController<SpoilerDetails>();
      // ignore: close_sinks
      final detailsUpdateController = StreamController<SpoilerDetails>();

      final key = GlobalKey();

      final data = SpoilerData(
          key: key,
          readyEvents: detailsReadyController,
          updateEvents: detailsUpdateController,
          isOpened: spoiler.isOpened);

      spoilersChildrenData.add(data);

      final updatedSpoiler = Spoiler(
        key: key,
        onReadyCallback: (details) {
          if (spoiler.onReadyCallback != null) spoiler.onReadyCallback(details);
          detailsReadyController.add(details);
        },
        onUpdateCallback: (details) {
          if (spoiler.onUpdateCallback != null) {
            spoiler.onUpdateCallback(details);
          }

          detailsUpdateController.add(details);
        },
        header: spoiler.header,
        child: spoiler.child,
        duration: spoiler.duration,
        isOpened: isOpened ? spoiler.isOpened : false, // need issue
        openCurve: spoiler.openCurve,
        closeCurve: spoiler.closeCurve,
        waitFirstCloseAnimationBeforeOpen:
            spoiler.waitFirstCloseAnimationBeforeOpen,
      );

      children.add(updatedSpoiler);
    }
  }

  Future<void> toggle() async {
    try {
      isOpened = isOpened ? false : true;

      isOpenController.add(isOpened);

      final openTween = Tween(begin: 0.0, end: getSpoilersHeight());
      final closeTween = Tween(begin: getSpoilersHeight(), end: 0.0);
      childHeightAnimation = CurvedAnimation(
              parent: childHeightAnimationController,
              curve: widget.openCurve,
              reverseCurve: widget.closeCurve)
          .drive(isOpened ? openTween : closeTween);

      childHeightAnimationController.reset();

      await childHeightAnimationController.forward().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  double getSpoilersHeaderHeight() {
    double height = 0.0;

    for (SpoilerData data in spoilersChildrenData) {
      height += data.details.headerHeight;
    }

    return height.toDouble();
  }

  double getSpoilersHeaderWidth() {
    double width = 0.0;

    for (SpoilerData data in spoilersChildrenData) {
      width += data.details.headerWidth;
    }

    return width.toDouble();
  }

  double getSpoilersChildHeight() {
    double height = 0.0;

    for (SpoilerData data in spoilersChildrenData) {
      height += data.details.childHeight;
    }

    return height.toDouble();
  }

  double getSpoilersHeight() =>
      getSpoilersHeaderHeight() + getSpoilersChildHeight();

  final GlobalKey _headerKey = GlobalKey(debugLabel: 'header');
  final GlobalKey _childKey = GlobalKey(debugLabel: 'child');

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: toggle,
            child: Container(
              key: Key('spoilers_header'),
              child: Container(
                key: _headerKey,
                child: widget.header != null
                    ? widget.header
                    : _buildDefaultHeader(),
              ),
            ),
          ),
          StreamBuilder<bool>(
              stream: isReady,
              initialData: false,
              builder: (context, snapshot) {
                if (snapshot.data) {
                  return AnimatedBuilder(
                    animation: childHeightAnimation,
                    builder: (BuildContext context, Widget child) => Container(
                      key: isOpened
                          ? Key('spoilers_child_opened')
                          : Key('spoilers_child_closed'),
                      height: childHeightAnimation.value > 0
                          ? childHeightAnimation.value
                          : 0,
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
                } else {
                  return Container(
                    key: isOpened
                        ? Key('spoilers_child_opened')
                        : Key('spoilers_child_closed'),
                    child: Container(
                      key: _childKey,
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
              }),
        ],
      );

  Widget _buildDefaultHeader() => StreamBuilder<bool>(
      stream: isOpen,
      initialData: isOpened,
      builder: (context, snapshot) => Container(
          margin: EdgeInsets.all(10),
          height: 20,
          width: 20,
          child: Center(
              child: Center(child: snapshot.data ? Text('-') : Text('+')))));
}

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'spoiler.dart';

class SpoilersDetails {
  bool isOpened;

  double headerWidth;
  double headerHeight;

  List<double> headersWidth;
  List<double> headersHeight;

  double childWidth;
  double childHeight;

  List<double> childrenWidth;
  List<double> childrenHeight;

  SpoilersDetails(
      {this.isOpened,
      this.headerWidth,
      this.headerHeight,
      this.headersWidth,
      this.headersHeight,
      this.childWidth,
      this.childHeight,
      this.childrenWidth,
      this.childrenHeight});
}

class Spoilers extends StatefulWidget {
  final Widget header;
  final List<Spoiler> children;

  final bool isOpened;

  final Curve openCurve;
  final Curve closeCurve;

  final Duration duration;

  final bool waitFirstCloseAnimationBeforeOpen;

  final StreamController<SpoilersDetails> spoilersDetails;

  const Spoilers(
      {this.header,
      this.children,
      this.isOpened = false,
      this.waitFirstCloseAnimationBeforeOpen = false,
      this.duration,
      this.spoilersDetails,
      this.openCurve = Curves.easeOutExpo,
      this.closeCurve = Curves.easeInExpo});

  @override
  SpoilersState createState() => SpoilersState();
}

class SpoilersState extends State<Spoilers>
    with SingleTickerProviderStateMixin {
  double headerWidth;
  double headerHeight;

  double childWidth;
  double childHeight;

  AnimationController animationController;
  Animation<double> animation;

  StreamController<bool> isReadyController = StreamController();
  Stream<bool> isReady;

  StreamController<bool> isOpenController = StreamController();
  Stream<bool> isOpen;

  bool isOpened;

  List<Spoiler> children;

  @override
  void initState() {
    super.initState();

    children = widget.children == null
        ? []
        : createChildrenDetailsControllers(widget.children);

    isOpened = widget.isOpened;

    isReady = isReadyController.stream.asBroadcastStream();

    isOpen = isOpenController.stream.asBroadcastStream();

    animationController = AnimationController(
        duration: widget.duration != null
            ? widget.duration
            : Duration(milliseconds: 400),
        vsync: this);

    animation = CurvedAnimation(
        parent: animationController,
        curve: widget.openCurve,
        reverseCurve: widget.closeCurve);

    final spoilersDetails = <SpoilerDetails>[];

    final spoilersDetailsQueue =
        Iterable<Future>.generate(children.length, (index) async {
      final spoiler = children[index];

      await for (SpoilerDetails details
          in spoiler.spoilerDetails.stream.asBroadcastStream()) {
        spoilersDetails.add(details);
        break;
      }
    });

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      headerWidth = _headerKey.currentContext.size.width;
      headerHeight = _headerKey.currentContext.size.height;

      childWidth = _childKey.currentContext.size.width;
      childHeight = _childKey.currentContext.size.height;

      animation =
          Tween(begin: 0.toDouble(), end: childHeight).animate(animation);

      if (spoilersDetailsQueue.isNotEmpty) {
        await Future.wait(spoilersDetailsQueue);
      }

//      children.forEach((spoiler) => spoiler.spoilerDetails.stream
//          .asBroadcastStream()
//          .listen((details) => print(details.isOpened)));

      final headersWidth = <double>[];
      final headersHeight = <double>[];

      final childrenWidth = <double>[];
      final childrenHeight = <double>[];

      for (SpoilerDetails details in spoilersDetails) {
        headersWidth.add(details.headerWidth);
        headersHeight.add(details.headerHeight);

        childrenWidth.add(details.childWidth);
        childrenHeight.add(details.childHeight);
      }

      animation.addListener(() => widget?.spoilersDetails?.add(SpoilersDetails(
          isOpened: isOpened,
          headerWidth: headerWidth,
          headerHeight: headerHeight,
          headersWidth: headersWidth,
          headersHeight: headersHeight,
          childWidth: childWidth,
          childHeight: childHeight,
          childrenWidth: childrenWidth,
          childrenHeight: childrenHeight)));

      widget?.spoilersDetails?.add(SpoilersDetails(
          isOpened: isOpened,
          headerWidth: headerWidth,
          headerHeight: headerHeight,
          headersWidth: headersWidth,
          headersHeight: headersHeight,
          childWidth: childWidth,
          childHeight: childHeight,
          childrenWidth: childrenWidth,
          childrenHeight: childrenHeight));

      isReadyController.add(true);

      try {
        if (widget.waitFirstCloseAnimationBeforeOpen) {
          isOpened
              ? await animationController.forward().orCancel
              : await animationController
                  .forward()
                  .orCancel
                  .whenComplete(() => animationController.reverse().orCancel);
        } else {
          isOpened
              ? await animationController.forward().orCancel
              : await animationController.reverse().orCancel;
        }
      } on TickerCanceled {
        // the animation got canceled, probably because we were disposed
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    isOpenController.close();
    isReadyController.close();
    children.forEach((spoiler) => spoiler.spoilerDetails.close());
    super.dispose();
  }

  List<Spoiler> createChildrenDetailsControllers(List<Spoiler> spoilers) {
    final spoilersWithDetailsControllers = <Spoiler>[];

    for (Spoiler spoiler in spoilers) {
      if (spoiler.spoilerDetails != null) {
        spoilersWithDetailsControllers.add(spoiler);
      } else {
        // ignore: close_sinks
        final detailsController = StreamController<SpoilerDetails>();

        final updatedSpoiler = Spoiler(
          spoilerDetails: detailsController,
          header: spoiler.header,
          child: spoiler.child,
          duration: spoiler.duration,
          isOpened: spoiler.isOpened,
          openCurve: spoiler.openCurve,
          closeCurve: spoiler.closeCurve,
          waitFirstCloseAnimationBeforeOpen:
              spoiler.waitFirstCloseAnimationBeforeOpen,
        );

        spoilersWithDetailsControllers.add(updatedSpoiler);
      }
    }

    return spoilersWithDetailsControllers;
  }

  Future<void> toggle() async {
    try {
      isOpened = isOpened ? false : true;

      isOpenController.add(isOpened);

      isOpened
          ? await animationController.forward().orCancel
          : await animationController.reverse().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

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
                    animation: animation,
                    builder: (BuildContext context, Widget child) => Container(
                      key: isOpened
                          ? Key('spoilers_child_opened')
                          : Key('spoilers_child_closed'),
                      height: animation.value > 0 ? animation.value : 0,
                      child: Wrap(
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                children != null ? children : [Container()],
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
                                children != null ? children : [Container()],
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

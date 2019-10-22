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

  List<double> childrenWidth;
  List<double> childrenHeight;

  SpoilersDetails(
      {this.isOpened,
      this.headerWidth,
      this.headerHeight,
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

  @override
  void initState() {
    super.initState();

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

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      headerWidth = _headerKey.currentContext.size.width;
      headerHeight = _headerKey.currentContext.size.height;

      childWidth = _childKey.currentContext.size.width;
      childHeight = _childKey.currentContext.size.height;

      animation =
          Tween(begin: 0.toDouble(), end: childHeight).animate(animation);

      if (widget.spoilersDetails != null) {
        animation.addListener(() => widget.spoilersDetails.add(SpoilersDetails(
            isOpened: isOpened,
            headerWidth: headerWidth,
            headerHeight: headerHeight,
            childrenWidth: [childWidth],
            childrenHeight: [childHeight])));

        widget.spoilersDetails.add(SpoilersDetails(
            isOpened: isOpened,
            headerWidth: headerWidth,
            headerHeight: headerHeight,
            childrenWidth: [childWidth],
            childrenHeight: [childHeight]));
      }

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
    super.dispose();
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
                            children: widget.children != null
                                ? widget.children
                                : [Container()],
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
                            children: widget.children != null
                                ? widget.children
                                : [Container()],
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

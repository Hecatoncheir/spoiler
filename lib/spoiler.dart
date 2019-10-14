import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class SpoilerDetails {
  bool isOpened;

  double headerWidth;
  double headerHeight;

  double childWidth;
  double childHeight;

  SpoilerDetails(
      {this.isOpened,
      this.headerWidth,
      this.headerHeight,
      this.childWidth,
      this.childHeight});
}

class Spoiler extends StatefulWidget {
  final Widget header;
  final Widget child;

  final bool isOpened;

  final Curve openCurve;
  final Curve closeCurve;

  final Duration duration;

  final bool waitFirstCloseAnimationBeforeOpen;

  final StreamController<SpoilerDetails> spoilerDetails;

  const Spoiler(
      {this.header,
      this.child,
      this.isOpened = false,
      this.waitFirstCloseAnimationBeforeOpen = false,
      this.duration,
      this.spoilerDetails,
      this.openCurve = Curves.easeOutExpo,
      this.closeCurve = Curves.easeInExpo});

  @override
  SpoilerState createState() => SpoilerState();
}

class SpoilerState extends State<Spoiler> with SingleTickerProviderStateMixin {
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

      if (widget.spoilerDetails != null) {
        animation.addListener(() => widget.spoilerDetails.add(SpoilerDetails(
            isOpened: isOpened,
            headerWidth: headerWidth,
            headerHeight: headerHeight,
            childWidth: childWidth,
            childHeight: childHeight)));

        widget.spoilerDetails.add(SpoilerDetails(
            isOpened: isOpened,
            headerWidth: headerWidth,
            headerHeight: headerHeight,
            childWidth: childWidth,
            childHeight: childHeight));
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
              key: Key('header'),
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
                      key: isOpened ? Key('child_opened') : Key('child_closed'),
                      height: animation.value > 0 ? animation.value : 0,
                      child: Wrap(
                        children: <Widget>[
                          widget.child != null ? widget.child : Container()
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    key: isOpened ? Key('child_opened') : Key('child_closed'),
                    child: Container(
                      key: _childKey,
                      child: Wrap(
                        children: <Widget>[
                          widget.child != null ? widget.child : Container()
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

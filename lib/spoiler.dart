import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:spoiler/models/spoiler_details.dart';

typedef OnReady = Function(SpoilerDetails);
typedef OnUpdate = Function(SpoilerDetails);

class Spoiler extends StatefulWidget {
  final Widget? header;
  final Widget? child;

  final bool isOpened;

  final bool leadingArrow;
  final bool trailingArrow;

  final Curve openCurve;
  final Curve closeCurve;

  final Duration duration;

  final bool waitFirstCloseAnimationBeforeOpen;

  final OnReady? onReadyCallback;
  final OnUpdate? onUpdateCallback;

  const Spoiler({
    Key? key,
    this.header,
    this.child,
    this.isOpened = false,
    this.leadingArrow = false,
    this.trailingArrow = false,
    this.waitFirstCloseAnimationBeforeOpen = false,
    this.duration = const Duration(milliseconds: 400),
    this.onReadyCallback,
    this.onUpdateCallback,
    this.openCurve = Curves.easeOutExpo,
    this.closeCurve = Curves.easeInExpo,
  }) : super(key: key);

  @override
  SpoilerState createState() => SpoilerState();
}

@visibleForTesting
class SpoilerState extends State<Spoiler> with SingleTickerProviderStateMixin {
  late final AnimationController childHeightAnimationController;
  late Animation<double> childHeightAnimation;

  late final StreamController<bool> isReadyController;
  late final Stream<bool> isReady;

  late final StreamController<bool> isOpenController;
  late final Stream<bool> isOpen;

  late bool isOpened;

  VoidCallback? onUpdateCallbackListener;

  late final GlobalKey _headerKey;
  late final GlobalKey _childKey;

  @override
  void initState() {
    super.initState();

    _headerKey = GlobalKey(debugLabel: 'spoiler_header');
    _childKey = GlobalKey(debugLabel: 'spoiler_child');

    isOpened = widget.isOpened;

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
      final headerElement = _headerKey.currentContext;
      final childElement = _childKey.currentContext;

      if (headerElement == null || childElement == null) return;

      final headerElementSize = headerElement.size;
      final childElementSize = childElement.size;

      if (headerElementSize == null || childElementSize == null) return;

      final headerWidth = headerElementSize.width;
      final headerHeight = headerElementSize.height;

      final childWidth = childElementSize.width;
      final childHeight = childElementSize.height;

      childHeightAnimation = Tween(
        begin: 0.0,
        end: childHeight,
      ).animate(childHeightAnimation);

      final onUpdateCallback = widget.onUpdateCallback;
      if (onUpdateCallback != null) {
        onUpdateCallbackListener = () {
          onUpdateCallback(
            SpoilerDetails(
              isOpened: isOpened,
              headerWidth: headerWidth,
              headerHeight: headerHeight,
              childWidth: childWidth,
              childHeight: childHeightAnimation.value,
            ),
          );
        };

        childHeightAnimation.addListener(onUpdateCallbackListener!);
      }

      final onReadyCallback = widget.onReadyCallback;
      if (onReadyCallback != null) {
        onReadyCallback(
          SpoilerDetails(
            isOpened: isOpened,
            headerWidth: headerWidth,
            headerHeight: headerHeight,
            childWidth: childWidth,
            childHeight: childHeight,
          ),
        );
      }

      isReadyController.add(true);

      try {
        if (widget.waitFirstCloseAnimationBeforeOpen) {
          isOpened
              ? await childHeightAnimationController.forward().orCancel
              : await childHeightAnimationController
                  .forward()
                  .orCancel
                  .whenComplete(
                  () {
                    return childHeightAnimationController.reverse().orCancel;
                  },
                );
        } else {
          isOpened
              ? await childHeightAnimationController.forward().orCancel
              : await childHeightAnimationController.reverse().orCancel;
        }
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

    super.dispose();
  }

  Future<void> toggle() async {
    try {
      isOpened = isOpened ? false : true;

      isOpenController.add(isOpened);

      isOpened
          ? await childHeightAnimationController.forward().orCancel
          : await childHeightAnimationController.reverse().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          key: const Key('spoiler_header'),
          onTap: () => setState(() {
            toggle();
          }),
          child: buildHeader(),
        ),
        buildChild(),
      ],
    );
  }

  Widget buildHeader() {
    final header = widget.header;

    return Container(
      key: _headerKey,
      child: header != null
          ? IntrinsicWidth(
              child: Row(
                children: <Widget>[
                  widget.leadingArrow
                      ? isOpened
                          ? const Icon(Icons.keyboard_arrow_up)
                          : const Icon(Icons.keyboard_arrow_down)
                      : Container(),
                  header,
                  widget.trailingArrow
                      ? isOpened
                          ? const Icon(Icons.keyboard_arrow_up)
                          : const Icon(Icons.keyboard_arrow_down)
                      : Container(),
                ],
              ),
            )
          : buildDefaultHeader(),
    );
  }

  Widget buildChild() {
    return StreamBuilder<bool>(
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
                    ? const Key('spoiler_child_opened')
                    : const Key('spoiler_child_closed'),
                child: Wrap(
                  children: <Widget>[
                    widget.child ?? Container(),
                  ],
                ),
              );
            },
          );
        }

        return Container(
          key: isOpened
              ? const Key('spoiler_child_opened')
              : const Key('spoiler_child_closed'),
          child: Container(
            key: _childKey,
            child: Wrap(
              children: <Widget>[
                widget.child ?? Container(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildDefaultHeader() {
    return StreamBuilder<bool>(
      stream: isOpen,
      initialData: isOpened,
      builder: (context, snapshot) {
        final isOpened = snapshot.data;
        if (isOpened == null) return Container();
        return isOpened ? const Text('-') : const Text('+');
      },
    );
  }
}

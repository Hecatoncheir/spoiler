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

  final bool waitCloseAnimationBeforeOpen;

  final OnReady? onReadyCallback;
  final OnUpdate? onUpdateCallback;

  const Spoiler({
    Key? key,
    this.header,
    this.child,
    this.isOpened = false,
    this.leadingArrow = false,
    this.trailingArrow = false,
    this.waitCloseAnimationBeforeOpen = false,
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
  late final GlobalKey headerKey;
  @visibleForTesting
  late final GlobalKey childKey;

  @override
  void initState() {
    super.initState();

    headerKey = GlobalKey(debugLabel: 'spoiler_header');
    childKey = GlobalKey(debugLabel: 'spoiler_child');

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
      final headerElement = headerKey.currentContext;
      final childElement = childKey.currentContext;

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
        if (widget.waitCloseAnimationBeforeOpen) {
          isOpened
              ? childHeightAnimationController.forward().orCancel
              : childHeightAnimationController.forward().orCancel.whenComplete(
                    () => childHeightAnimationController.reverse().orCancel,
                  );
        } else {
          isOpened
              ? childHeightAnimationController.forward().orCancel
              : childHeightAnimationController.reverse().orCancel;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          key: const Key('spoiler_header'),
          onTap: () async => toggle(),
          child: buildHeader(),
        ),
        buildChild(),
      ],
    );
  }

  @visibleForTesting
  Future<void> toggle() async {
    try {
      isOpened = isOpened ? false : true;

      isOpenController.add(isOpened);

      isOpened
          ? childHeightAnimationController.forward().orCancel
          : childHeightAnimationController.reverse().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  @visibleForTesting
  Widget buildHeader() {
    final header = widget.header;

    return Container(
      key: headerKey,
      child: header != null
          ? IntrinsicWidth(
              child: Row(
                children: <Widget>[
                  widget.leadingArrow ? buildLeadingArrow() : Container(),
                  header,
                  widget.trailingArrow ? buildTrailingArrow() : Container(),
                ],
              ),
            )
          : buildDefaultHeader(),
    );
  }

  @visibleForTesting
  Widget buildLeadingArrow() {
    return StreamBuilder<bool>(
      stream: isOpen,
      initialData: isOpened,
      builder: (context, snapshot) {
        final isOpened = snapshot.data;
        if (isOpened == null) return Container();

        return isOpened
            ? const Icon(Icons.keyboard_arrow_up)
            : const Icon(Icons.keyboard_arrow_down);
      },
    );
  }

  @visibleForTesting
  Widget buildTrailingArrow() {
    return StreamBuilder<bool>(
      stream: isOpen,
      initialData: isOpened,
      builder: (context, snapshot) {
        final isOpened = snapshot.data;
        if (isOpened == null) return Container();

        return isOpened
            ? const Icon(Icons.keyboard_arrow_up)
            : const Icon(Icons.keyboard_arrow_down);
      },
    );
  }

  @visibleForTesting
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
            child: Wrap(
              clipBehavior: Clip.hardEdge,
              children: [
                widget.child ?? Container(),
              ],
            ),
            builder: (BuildContext context, Widget? child) {
              return SizedBox(
                height: childHeightAnimation.value,
                key: isOpened
                    ? const Key('spoiler_child_opened')
                    : const Key('spoiler_child_closed'),
                child: child ?? Container(),
              );
            },
          );
        }

        if (!isReady) {
          return Container(
            key: isOpened
                ? const Key('spoiler_child_opened')
                : const Key('spoiler_child_closed'),
            child: Container(
              key: childKey,
              child: Wrap(
                clipBehavior: Clip.hardEdge,
                children: [
                  widget.child ?? Container(),
                ],
              ),
            ),
          );
        }

        return Container();
      },
    );
  }

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

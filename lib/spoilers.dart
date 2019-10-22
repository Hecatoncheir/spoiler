import 'dart:async';

import 'package:flutter/widgets.dart';

import 'spoiler.dart';

class Spoilers extends StatefulWidget {
  final Widget header;
  final List<Spoiler> children;
  final bool isOpened;

  const Spoilers({this.header, this.children, this.isOpened = false});

  @override
  _SpoilersState createState() => _SpoilersState();
}

class _SpoilersState extends State<Spoilers> {
  StreamController<bool> isOpenController = StreamController();
  Stream<bool> isOpen;

  bool isOpened;

  @override
  void initState() {
    super.initState();

    isOpened = widget.isOpened;

    isOpen = isOpenController.stream.asBroadcastStream();
  }

  @override
  void dispose() {
    isOpenController.close();
    super.dispose();
  }

  final GlobalKey _headerKey = GlobalKey(debugLabel: 'header');

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(),
          if (widget.children != null) ...widget.children
        ],
      );

  Widget _buildHeader() => Container(
        key: Key('header'),
        child: Container(
            key: _headerKey,
            child:
                widget.header != null ? widget.header : _buildDefaultHeader()),
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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:spoiler/models/spoiler_details.dart';

class SpoilerData {
  StreamController<SpoilerDetails>? updateEvents;
  StreamController<SpoilerDetails>? readyEvents;

  SpoilerDetails? details;

  GlobalKey? key;

  bool? isOpened;

  SpoilerData({
    this.key,
    this.updateEvents,
    this.readyEvents,
    this.details,
    this.isOpened,
  });
}

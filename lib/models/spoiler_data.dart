import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:spoiler/models/spoiler_details.dart';

class SpoilerData {
  // ignore: close_sinks
  StreamController<SpoilerDetails> updateEvents;
  // ignore: close_sinks
  StreamController<SpoilerDetails> readyEvents;
  SpoilerDetails details;

  GlobalKey key;

  bool isOpened;

  SpoilerData(
      {this.key,
      this.updateEvents,
      this.readyEvents,
      this.details,
      this.isOpened});
}

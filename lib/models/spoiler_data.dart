import 'dart:async';

import 'package:spoiler/models/spoiler_details.dart';

class SpoilerData {
  // ignore: close_sinks
  StreamController<SpoilerDetails> updateEvents;
  // ignore: close_sinks
  StreamController<SpoilerDetails> readyEvents;
  SpoilerDetails details;

  bool isOpened;

  SpoilerData(
      {this.updateEvents, this.readyEvents, this.details, this.isOpened});
}

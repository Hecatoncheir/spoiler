import 'package:spoiler/models/spoiler_data.dart';

class SpoilersDetails {
  bool isOpened;

  double headerWidth;
  double headerHeight;

  List<SpoilerData> spoilersDetails;

  double childWidth;
  double childHeight;

  SpoilersDetails(
      {this.isOpened,
      this.headerWidth,
      this.headerHeight,
      this.childWidth,
      this.childHeight,
      this.spoilersDetails});
}

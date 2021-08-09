import 'package:spoiler/models/spoiler_data.dart';

class SpoilersDetails {
  bool isOpened;

  double headerWidth;
  double headerHeight;

  List<SpoilerData> spoilersDetails;

  double childWidth;
  double childHeight;

  SpoilersDetails({
    required this.isOpened,
    required this.headerWidth,
    required this.headerHeight,
    required this.childWidth,
    required this.childHeight,
    required this.spoilersDetails,
  });
}

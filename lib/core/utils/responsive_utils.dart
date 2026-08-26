import 'package:flutter/material.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double devicePixelRatio;
  static late double statusBarHeight;
  static late double bottomBarHeight;

  // Base design dimensions (e.g., iPhone 13/14)
  static const double baseWidth = 375.0;
  static const double baseHeight = 812.0;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
    statusBarHeight = _mediaQueryData.padding.top;
    bottomBarHeight = _mediaQueryData.padding.bottom;
  }

  /// Get the responsive width based on design width
  static double setWidth(double width) {
    return (width / baseWidth) * screenWidth;
  }

  /// Get the responsive height based on design height
  static double setHeight(double height) {
    return (height / baseHeight) * screenHeight;
  }

  /// Get the responsive font size based on screen width
  static double setSp(double fontSize) {
    return (fontSize / baseWidth) * screenWidth;
  }
}

extension ResponsiveDoubleExtension on double {
  double get w => Responsive.setWidth(this);
  double get h => Responsive.setHeight(this);
  double get sp => Responsive.setSp(this);
}

extension ResponsiveIntExtension on int {
  double get w => Responsive.setWidth(this.toDouble());
  double get h => Responsive.setHeight(this.toDouble());
  double get sp => Responsive.setSp(this.toDouble());
}

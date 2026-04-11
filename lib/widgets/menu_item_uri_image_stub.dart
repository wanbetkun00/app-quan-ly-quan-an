import 'package:flutter/material.dart';

/// Fallback if neither `dart.library.io` nor `dart.library.html` applies (unused in Flutter).
Widget buildMenuItemUriImage(
  String uri, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  ImageLoadingBuilder? loadingBuilder,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return SizedBox(width: width, height: height);
}

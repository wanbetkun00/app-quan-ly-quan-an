import 'dart:io';

import 'package:flutter/material.dart';

Widget buildMenuItemUriImage(
  String uri, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  ImageLoadingBuilder? loadingBuilder,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (uri.startsWith('http')) {
    return Image.network(
      uri,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
  try {
    final file = File(uri);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
  } catch (_) {
    // ignore
  }
  return _fallback(width, height);
}

Widget _fallback(double? width, double? height) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey[300],
    child: const Icon(Icons.image_not_supported),
  );
}

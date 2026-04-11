import 'package:flutter/material.dart';

import 'menu_item_uri_image_stub.dart'
    if (dart.library.io) 'menu_item_uri_image_io.dart'
    if (dart.library.html) 'menu_item_uri_image_web.dart' as impl;

/// Renders a menu image from either an `http(s)` URL or a local file path (VM/desktop/mobile only).
class MenuItemUriImage extends StatelessWidget {
  final String uri;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  const MenuItemUriImage({
    super.key,
    required this.uri,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildMenuItemUriImage(
      uri,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}

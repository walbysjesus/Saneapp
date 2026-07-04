import 'package:flutter/widgets.dart';

import 'adaptive_image_provider_stub.dart'
    if (dart.library.io) 'adaptive_image_provider_io.dart' as impl;

ImageProvider<Object>? resolveAdaptiveImageProvider(String? source) {
  return impl.resolveAdaptiveImageProvider(source);
}
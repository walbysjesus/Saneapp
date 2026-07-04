import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object>? resolveAdaptiveImageProvider(String? source) {
  final normalized = source?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(normalized);
  final scheme = uri?.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return NetworkImage(normalized);
  }

  return FileImage(File(normalized));
}
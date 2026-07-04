import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class SaneCachedImage extends StatefulWidget {
  const SaneCachedImage({
    super.key,
    required this.imageUrl,
    required this.placeholder,
    required this.error,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final Widget placeholder;
  final Widget error;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  State<SaneCachedImage> createState() => _SaneCachedImageState();
}

class _SaneCachedImageState extends State<SaneCachedImage> {
  Future<File?>? _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = _ImageDiskCacheService.getCachedFile(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant SaneCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _fileFuture = _ImageDiskCacheService.getCachedFile(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.trim().isEmpty) {
      return widget.error;
    }

    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder;
        }

        final file = snapshot.data;
        if (file != null && file.existsSync()) {
          return Image.file(
            file,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
          );
        }

        return Image.network(
          widget.imageUrl,
          height: widget.height,
          width: widget.width,
          fit: widget.fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return widget.placeholder;
          },
          errorBuilder: (context, error, stackTrace) {
            return widget.error;
          },
        );
      },
    );
  }
}

class _ImageDiskCacheService {
  static Future<File?> getCachedFile(String imageUrl) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return null;
    }

    try {
      final cacheDir = await _cacheDirectory();
      final file = File('${cacheDir.path}/${_hashUrl(url)}.img');

      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<Directory> _cacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/saneapp_image_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _hashUrl(String input) {
    var hash = 2166136261;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}

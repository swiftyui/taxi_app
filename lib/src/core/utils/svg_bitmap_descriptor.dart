import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract final class PNGBitmapDescriptor {
  static Future<BitmapDescriptor> fromFilePath(
    String filePath, {
    int width = 96,
    int height = 96,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    return BitmapDescriptor.fromBytes(Uint8List.fromList(bytes));
  }
}

abstract final class SvgBitmapDescriptor {
  static Future<BitmapDescriptor> fromFilePath(
    String filePath, {
    int width = 96,
    int height = 96,
  }) async =>
      _render(SvgFileLoader(File(filePath)), width: width, height: height);

  static Future<BitmapDescriptor> fromAsset(
    String assetPath, {
    int width = 96,
    int height = 96,
    String? package,
  }) async => _render(
    SvgAssetLoader(assetPath, packageName: package),
    width: width,
    height: height,
  );

  static Future<BitmapDescriptor> _render(
    BytesLoader loader, {
    required int width,
    required int height,
  }) async {
    final pictureInfo = await vg.loadPicture(loader, null);

    try {
      final ui.Image image = await pictureInfo.picture.toImage(width, height);

      try {
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData == null) {
          throw StateError('Failed to convert SVG to PNG.');
        }

        return BitmapDescriptor.bytes(
          byteData.buffer.asUint8List(),
          width: width.toDouble(),
          height: height.toDouble(),
        );
      } finally {
        image.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  }
}

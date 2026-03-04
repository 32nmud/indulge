import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static final Logger _logger = Logger('ExportService');

  /// Captures the widget identified by [key] into a JPEG [Uint8List].
  ///
  /// [pixelRatio] controls the output resolution relative to the widget's
  /// logical size — 3.0 gives you 3× the logical pixels (e.g. 360×360 lp
  /// → 1080×1080 px), which is suitable for social sharing.
  ///
  /// [jpegQuality] is 0–100. Defaults to 92 for a good size/quality balance.
  static Future<Uint8List> captureToJpeg(
    GlobalKey key, {
    double pixelRatio = 3.0,
    int jpegQuality = 92,
  }) async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null) {
      throw StateError(
        'ExportService: no render object found for the provided key. '
        'Make sure the widget is currently in the tree.',
      );
    }

    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        'ExportService: the widget associated with the key must be wrapped in '
        'a RepaintBoundary widget.',
      );
    }

    // Capture to a ui.Image at the desired pixel density.
    final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);

    // Encode to raw PNG bytes first (Flutter has no built-in JPEG encoder).
    final ByteData? pngByteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (pngByteData == null) {
      throw StateError('ExportService: failed to encode image to PNG bytes.');
    }
    final Uint8List pngBytes = pngByteData.buffer.asUint8List();

    image.dispose();

    // Compress / transcode to JPEG via flutter_image_compress.
    final Uint8List jpegBytes = await FlutterImageCompress.compressWithList(
      pngBytes,
      format: CompressFormat.jpeg,
      quality: jpegQuality,
    );

    _logger.fine(
      'Captured widget: PNG=${pngBytes.length} bytes → '
      'JPEG=${jpegBytes.length} bytes (quality=$jpegQuality)',
    );

    return jpegBytes;
  }

  /// Captures the widget identified by [key] and immediately opens the
  /// platform share sheet.
  ///
  /// [filename] is the suggested file name (without extension) used when
  /// saving to the device or sharing to other apps.
  static Future<void> captureAndShare(
    GlobalKey key, {
    String filename = 'indulge_event',
    double pixelRatio = 3.0,
    int jpegQuality = 92,
    String? shareText,
  }) async {
    final Uint8List jpegBytes = await captureToJpeg(
      key,
      pixelRatio: pixelRatio,
      jpegQuality: jpegQuality,
    );

    final File file = await _writeTempFile(jpegBytes, filename);

    final XFile xFile = XFile(
      file.path,
      mimeType: 'image/jpeg',
      name: '$filename.jpg',
    );

    await SharePlus.instance.share(
      ShareParams(files: [xFile], text: shareText),
    );
  }

  /// Captures the widget identified by [key] and opens the platform
  /// "save file" dialog so the user can choose where to store the JPEG.
  ///
  /// Returns `true` if the file was saved, `false` if the user cancelled.
  static Future<bool> captureAndSave(
    GlobalKey key, {
    String filename = 'indulge_event',
    double pixelRatio = 3.0,
    int jpegQuality = 92,
  }) async {
    final Uint8List jpegBytes = await captureToJpeg(
      key,
      pixelRatio: pixelRatio,
      jpegQuality: jpegQuality,
    );

    final File tempFile = await _writeTempFile(jpegBytes, filename);

    final params = SaveFileDialogParams(
      sourceFilePath: tempFile.path,
      fileName: '$filename.jpg',
    );

    final savedPath = await FlutterFileDialog.saveFile(params: params);
    _logger.fine(
      savedPath != null ? 'File saved to: $savedPath' : 'Save cancelled',
    );
    return savedPath != null;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<File> _writeTempFile(Uint8List bytes, String filename) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String path =
        '${tempDir.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    _logger.fine('Wrote temp file: $path (${bytes.length} bytes)');
    return file;
  }
}

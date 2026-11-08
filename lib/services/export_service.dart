import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isMobile => _isAndroid || _isIOS;

  static String _stamp() =>
      'invitation_${DateTime.now().millisecondsSinceEpoch}';

  /// Captures the widget under [key] (must be a RepaintBoundary) as PNG bytes.
  static Future<Uint8List> capturePng(
    GlobalKey key, {
    double pixelRatio = 4,
  }) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Wraps the PNG in a single-page 5x7in PDF (same 5:7 ratio as the card).
  static Future<Uint8List> pngToPdf(Uint8List png) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(png);
    final format = PdfPageFormat(
      5 * PdfPageFormat.inch,
      7 * PdfPageFormat.inch,
      marginAll: 0,
    );
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.cover),
      ),
    );
    return doc.save();
  }

  /// PNG -> phone gallery (Android/iOS). Web/desktop -> normal file download.
  /// Returns a message to show the user.
  static Future<String> savePng(Uint8List png) async {
    if (_isMobile) {
      try {
        await Gal.putImageBytes(png);
        return 'Saved to gallery';
      } on GalException catch (e) {
        return 'Failed to save: $e';
      } catch (e) {
        return 'Failed to save: $e';
      }
    }
    await FileSaver.instance.saveFile(
      name: _stamp(),
      bytes: png,
      ext: 'png',
      mimeType: MimeType.png,
    );
    return 'PNG saved';
  }

  /// PDF can't go in the gallery, so it goes to Files/Downloads.
  /// Android: system "save as" picker. iOS: share sheet (has "Save to Files").
  /// Web/desktop: normal download.
  static Future<String> savePdf(Uint8List pdf) async {
    if (_isIOS) {
      await Printing.sharePdf(bytes: pdf, filename: '${_stamp()}.pdf');
      return 'Choose "Save to Files"';
    }
    if (_isAndroid) {
      try {
        final path = await FileSaver.instance.saveAs(
          name: _stamp(),
          bytes: pdf,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        return path == null ? 'Save cancelled' : 'PDF saved';
      } catch (e) {
        try {
          await FileSaver.instance.saveFile(
            name: _stamp(),
            bytes: pdf,
            ext: 'pdf',
            mimeType: MimeType.pdf,
          );
          return 'PDF saved';
        } catch (_) {
          await Printing.sharePdf(bytes: pdf, filename: '${_stamp()}.pdf');
          return 'PDF shared';
        }
      }
    }
    try {
      await FileSaver.instance.saveFile(
        name: _stamp(),
        bytes: pdf,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      return 'PDF saved';
    } catch (e) {
      await Printing.sharePdf(bytes: pdf, filename: '${_stamp()}.pdf');
      return 'PDF shared';
    }
  }

  // Keep these for a separate "Share" button if you want one.
  static Future<void> sharePng(Uint8List png) => Share.shareXFiles([
    XFile.fromData(png, mimeType: 'image/png', name: 'invitation.png'),
  ], text: 'Check out my invitation!');

  static Future<void> sharePdf(Uint8List pdf) =>
      Printing.sharePdf(bytes: pdf, filename: 'invitation.pdf');
}

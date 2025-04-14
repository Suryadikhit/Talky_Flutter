import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<String> createInitialsAvatarImage(String initials) async {
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final size = 128.0;

  final paint = Paint()..color = const Color(0xFF00897B);
  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

  final textPainter = TextPainter(
    text: TextSpan(
      text: initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
  );

  final image = await pictureRecorder.endRecording().toImage(128, 128);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/avatar_$initials.png';
  final file = File(filePath);
  await file.writeAsBytes(pngBytes);

  return filePath;
}
